import json
import psycopg
from pathlib import Path
from ollama import Client

# 1. Carregar a configuração de forma robusta
BASE_DIR = Path(__file__).resolve().parent

with open(BASE_DIR / "config.json", encoding="utf-8") as f:
    config = json.load(f)

# 2. Conectar ao PostgreSQL
print("Conectando ao banco de dados...")
db = config["database"]
try:
    conn = psycopg.connect(
        host=db["host"],
        port=db["port"],
        dbname=db["dbname"],
        user=db["user"],
        password=db["password"]
    )
    print("Conexão com o banco bem-sucedida!")
except Exception as e:
    print(f"Erro ao conectar ao banco: {e}")
    raise SystemExit(1)

# 3. Conectar ao Ollama
print("Conectando ao Ollama...")
ollama_config = config["ollama"]
client = Client(
    host=ollama_config["host"]
)

# 4. Extrair o DDL do arquivo Projeto.txt
print("Lendo o arquivo Projeto.txt e extraindo o DDL...")
projeto_path = BASE_DIR.parent / "Projeto.txt"

if not projeto_path.exists():
    print("Erro: Projeto.txt não encontrado.")
    raise SystemExit(1)

projeto = projeto_path.read_text(encoding="utf-8")
try:
    ddl = projeto.split("3. DDL COMPLETO", 1)[1]
    ddl = ddl.split("4. CONSULTAS", 1)[0]
    ddl = ddl.strip()
    # print("DDL extraído com sucesso:\n", ddl) # Descomente para testar se extraiu certo
except IndexError:
    print("Erro ao extrair o DDL. Verifique se o template do Projeto.txt está rigorosamente correto.")

# Exemplo de chamada ao modelo Ollama com base no prompt
def consultar_ollama(prompt):
    response = client.chat(
        model=ollama_config["model"],
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ]
    )
    resposta = response["message"]["content"]
    return resposta

# TODO: A partir daqui você deve desenvolver a lógica do seu menu/protótipo, 
# criar as tabelas com o DDL extraído, inserir o menu interativo, executar 
# as consultas prontas e a conversão de linguagem natural via Ollama.

# Sempre feche a conexão com o banco ao finalizar
conn.close()