## Executar o comando 

```
pip install -r requirements-dev.txt
```

## Variáveis de ambiente (.env)

O projeto lê as configurações de um arquivo `.env` na raiz (não versionado).
Além das URLs e credenciais, há uma variável opcional:

- `BROWSER_EXECUTABLE_PATH` — caminho de um navegador instalado no sistema
  (ex.: `C:/Program Files/Google/Chrome/Application/chrome.exe`). Se **vazia
  ou ausente**, os testes usam o chromium empacotado do Playwright (padrão,
  recomendado em CI). Defina-a apenas em máquinas onde o chromium empacotado
  não inicia — por exemplo, quando falta a dependência `msvcp140_1.dll`
  (Microsoft Visual C++ Redistributable) no Windows.

### Portal do Titular

Variáveis adicionais usadas pelos testes em `src/tests/portal_titular/`:

- `URL_PORTAL_TITULAR` — URL do Portal do Titular (ex.: `https://portal-hml.evoluaenergia.com.br/`)
- `EMAIL_PORTAL_TITULAR` / `PASSWORD_PORTAL_TITULAR` — credenciais de um usuário de teste válido
- `CPF_TITULAR` — CPF (com ou sem formatação) do titular usado para login, necessário para
  localizar o Contact correspondente no Salesforce e validar que a alteração de e-mail persistiu