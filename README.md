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

### Salesforce (`src/API`, `src/keywords/salesforce-keywords.resource`)

- `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET`, `SALESFORCE_AUTH_URL` —
  credenciais da Connected App (fluxo OAuth Client Credentials).

### App mobile (`src/tests/app_mobile`)

Testes do app do cliente (Portal do Cliente, Android) via Appium/UiAutomator2.

Pré-requisitos, além do `pip install -r requirements-dev.txt`:

- Android Studio + SDK + um emulador criado (AVD Manager)
- Appium Server (`npm install -g appium && appium driver install uiautomator2`),
  rodando (`appium`) antes de executar os testes
- Emulador ligado com o app já instalado (Play Store)

Variáveis de ambiente:

- `EMAIL_APP_MOBILE`, `PASSWORD_APP_MOBILE` — credenciais da conta de teste
- Opcionais (têm default para o emulador local padrão; só defina se o seu
  ambiente for diferente):
  - `APPIUM_SERVER_URL` (default `http://127.0.0.1:4723`)
  - `ANDROID_DEVICE_NAME` (default `emulator-5554`)
  - `ANDROID_PLATFORM_VERSION` (default `14`)
  - `APP_MOBILE_PACKAGE` (default `com.evoluafrontendportal`)
  - `APP_MOBILE_ACTIVITY` (default `com.evoluafrontendportal.MainActivity`)
- `ANDROID_HOME` — variável de ambiente do sistema (não do `.env`) apontando
  para o Android SDK; necessária para localizar o `adb`

Executar um teste específico:

```
robot --outputdir results src/tests/app_mobile/login.robot
```
