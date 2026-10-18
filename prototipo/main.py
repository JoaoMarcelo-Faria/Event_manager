import json
import re  # será usado em extrair_consultas()
from pathlib import Path
import psycopg
from ollama import Client

BASE_DIR = Path(__file__).resolve().parent

# ======================================================================
# 1. PREPARAÇÃO E OBTENÇÃO DE CONFIGURAÇÕES
# ======================================================================

def carregar_config():
    with open(BASE_DIR / "config.json", encoding="utf-8") as f:
        return json.load(f)

def conectar_banco(config):
    db = config["database"]
    try:
        return psycopg.connect(
            host=db["host"],
            port=db["port"],
            dbname=db["dbname"],
            user=db["user"],
            password=db["password"],
        )
    except psycopg.Error as e:
        print(f"Erro ao conectar ao banco: {e}")
        raise SystemExit(1)

def criar_cliente_ollama(config):
    ollama_config = config["ollama"]
    return Client(host=ollama_config["host"])

def ler_projeto():
    projeto_path = BASE_DIR.parent / "Projeto.txt"
    if not projeto_path.exists():
        print("Erro: Projeto.txt não encontrado.")
        raise SystemExit(1)
    return projeto_path.read_text(encoding="utf-8")


def remover_separadores(texto):
    """Tira as linhas decorativas '=====' do Projeto.txt (não são SQL)."""
    linhas = [l for l in texto.splitlines() if not l.strip().startswith("====")]
    return "\n".join(linhas).strip()

def extrair_ddl(projeto):
    try:
        ddl = projeto.split("3. DDL COMPLETO", 1)[1]
        ddl = ddl.split("4. CONSULTAS", 1)[0]
    except IndexError:
        print("Erro: seções '3. DDL COMPLETO' / '4. CONSULTAS' não encontradas.")
        raise SystemExit(1)
    return remover_separadores(ddl)

def preparar_banco(conn, ddl):
    """Executa o DDL inteiro de uma vez e confirma (commit)."""
    if not ddl or ddl.startswith("[Inserir"):
        print("Erro: a seção 3 do Projeto.txt ainda não tem o DDL.")
        raise SystemExit(1)
    try:
        conn.execute(ddl)
        conn.commit()
        print("Banco preparado (DDL executado).")
    except psycopg.Error as e:
        conn.rollback()
        print(f"Erro ao executar o DDL: {e}")
        raise SystemExit(1)

# ======================================================================
# 2. FUNÇÕES DO MENU
# ======================================================================

def exibir_menu():
    print("\n=== Sistema de Gestão de Eventos e Espaços ===")
    print("1. Executar as consultas do projeto")
    print("2. Fazer uma pergunta em linguagem natural")
    print("3. Sair")


def extrair_consultas(projeto):
    # Pega só o trecho entre "4. CONSULTAS" e "FIM DO ARQUIVO"
    texto = projeto.split("4. CONSULTAS", 1)[1]
    texto = texto.split("FIM DO ARQUIVO", 1)[0]
    texto = remover_separadores(texto)
    
    consultas = []                              # lista vazia (vetor que cresce)
    blocos = texto.split("CONSULTA ")
    
    for bloco in blocos[1:]:
        antes_do_sql, sql = bloco.split("SQL:", 1)           
        objetivo = antes_do_sql.split("OBJETIVO:", 1)[1]
        consultas.append((objetivo.strip(), sql.strip()))  
    
    # validação
    if len(consultas) != 5:
        print(f"Erro: esperava 5 consultas, mas encontrei {len(consultas)}.")
        raise SystemExit(1)       
    
    return consultas

def imprimir_tabela(colunas, linhas):
    if not linhas:
        print("(nenhum resultado)")
        return

    # 1. largura de cada coluna: começa com o tamanho do nome
    larguras = []
    for nome in colunas:
        larguras.append(len(nome))

    # 2. aumenta a largura se algum valor for maior que ela
    for linha in linhas:
        for i in range(len(linha)):
            tamanho = len(str(linha[i]))
            if tamanho > larguras[i]:
                larguras[i] = tamanho                     

    # 3. cabeçalho
    for i in range(len(colunas)):
        print(colunas[i].ljust(larguras[i]), end=" | ")
    print()
    print("-" * (sum(larguras) + 3 * len(colunas)))

    # 4. linhas de dados
    for linha in linhas:
        for i in range(len(linha)):
            print(str(linha[i]).ljust(larguras[i]), end=" | ")
        print()


def executar_consultas(conn, projeto):
    consultas = extrair_consultas(projeto)

    for numero, (objetivo, sql) in enumerate(consultas, 1):
        print(f"\n--- Consulta {numero}: {objetivo} ---")
        try:
            cur = conn.execute(sql)                         
            colunas = [col.name for col in cur.description]
            linhas = cur.fetchall()                               
            imprimir_tabela(colunas, linhas)
        except psycopg.Error as e:
            print(f"Erro ao executar a consulta: {e}")
            conn.rollback()                                       

def montar_prompt(ddl, pergunta):
    return f"""Você converte perguntas em português para SQL do PostgreSQL.

    Esquema do banco:
    {ddl}

    Regras:
    - Responda SOMENTE com a consulta SQL, sem explicações e sem markdown.
    - Gere apenas comandos SELECT.
    - Use apenas as tabelas e colunas do esquema acima.

    Pergunta: {pergunta}"""

def consultar_ollama(client, config, prompt):
    try:
        response = client.chat(
            model=config["ollama"]["model"],
            messages=[{"role": "user", "content": prompt}],
        )
        return response["message"]["content"]
    except Exception as e:
        print(f"Erro ao consultar o Ollama: {e}")
        return None

def limpar_sql(resposta):
    # descarta o bloco de raciocínio, ficando só com o que vem depois dele
    if "</think>" in resposta:
        resposta = resposta.split("</think>")[-1]            

    # tira as cercas de markdown
    resposta = resposta.replace("```sql", "").replace('```', "")  

    return resposta.strip()                                      

def eh_select(sql):
    return sql.lower().startswith("select")  

def executar_e_imprimir(conn, sql):
    try:
        cur = conn.execute(sql)
        colunas = [col.name for col in cur.description]
        linhas = cur.fetchall()
        imprimir_tabela(colunas, linhas)
    except psycopg.Error as e:
        print(f"Erro ao executar a consulta: {e}")
        conn.rollback()                       

def consulta_linguagem_natural(conn, client, config, ddl):
    pergunta = input("O que você deseja consultar?").strip()
    if not pergunta:
        print("Pergunta vazia. Tente novamente.")
        return

    prompt = montar_prompt(ddl, pergunta)
    resposta = consultar_ollama(client, config, prompt)
    if resposta is None:
        print("Não foi possível obter uma resposta do Ollama.")
        return

    sql = limpar_sql(resposta)
    print(f"\nSQL gerado:\n{sql}\n")
 
    if not eh_select(sql):
        print("Erro: o modelo não gerou um único SELECT. Consulta não executada.")
        return

    executar_e_imprimir(conn, sql)
    
# ======================================================================
# 3. MAIN
# ======================================================================

def main():
    config = carregar_config()
    conn = conectar_banco(config)
    print("Conexão com o banco bem-sucedida!")
    try:
        client = criar_cliente_ollama(config)
        projeto = ler_projeto()
        ddl = extrair_ddl(projeto)
        preparar_banco(conn, ddl)

        while True:
            exibir_menu()
            opcao = input("Escolha uma opção: ").strip()

            match opcao:
                case "1":
                    executar_consultas(conn, projeto)
                case "2":
                    consulta_linguagem_natural(conn, client, config, ddl)
                case "3":
                    print("Encerrando.")
                    break
                case _:
                    print("Opção inválida. Digite 1, 2 ou 3.")
    except KeyboardInterrupt:
        print("\nEncerrado pelo usuário.")
    finally:
        conn.close()

if __name__ == "__main__":
    main()