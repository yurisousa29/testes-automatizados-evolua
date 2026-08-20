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

### Portal do Titular (`src/tests/portal_titular`)

Testes do Portal do Titular (portal web, `robotframework-browser`/Playwright). Cobertura
espelhada da suíte do app mobile (`src/tests/app_mobile`) — mesmo backend, mesmas
mensagens de erro e regras de negócio na maioria dos fluxos.

Variáveis de ambiente:

- `URL_PORTAL_TITULAR` — URL do Portal do Titular (ex.: `https://portal-hml.evoluaenergia.com.br/`)
- `EMAIL_PORTAL_TITULAR` / `PASSWORD_PORTAL_TITULAR` — credenciais de um usuário de teste válido
- `CPF_TITULAR` — CPF (com ou sem formatação) do titular usado para login, necessário para
  localizar o Contact correspondente no Salesforce e validar que a alteração de e-mail persistiu
- `PORTAL_EMAIL_TESTE` — opcional, e-mail usado no teste de alteração cadastral com sucesso
  (tem um default gerado por Faker se não definida)

Arquivos de teste:

| Arquivo | Cobre |
|---|---|
| `login_credenciais_invalidas.robot` | e-mail não cadastrado / senha incorreta |
| `login_sem_conexao.robot` | contexto do navegador offline (`Set Offline`) |
| `indicacao.robot` | banner de indicação na home + link de compartilhamento (WhatsApp) |
| `dados_cadastrais.robot` | alteração de e-mail cadastral, com sucesso e com erro, validado via Salesforce |
| `fatura.robot` | popup de 2ª via (habilitação progressiva Ano/Mês/Gerar) + aba Pagamento |
| `instalacao.robot` | número de instalação via Perfil → Renomear instalação |
| `contas_unificacao.robot` | banner de unificação de contas, validado via Salesforce |
| `contas_historico.robot` | histórico completo de contas |
| `contas_pagamento.robot` / `contas_encaminhar.robot` | ⚠️ pendentes — ver limitação abaixo |
| `indicacao_tab_indicar_amigo.robot` | formulário "Indique um amigo" (habilitação, máscara, validação) |
| `indicacao_tab_compartilhar.robot` | botão "Compartilhar" da aba Indicação |
| `indicacao_tab_faq.robot` | "Como funciona o Rede Evolua+?" |
| `indicacao_tab_chave_pix.robot` | navegação até "Alterar chave pix" (não submete dados) |

#### ⚠️ Limitações conhecidas (2026-08-20)

- **Aba "Consumo" da 2ª via**: ficou travada num spinner infinito em execuções manuais
  contra homologação. `IR PARA ABA CONSUMO` só confirma a navegação, sem validar os
  valores exibidos — investigar antes de fortalecer essa validação.
- **`contas_pagamento.robot` / `contas_encaminhar.robot`**: a conta de teste configurada
  não tinha nenhuma conta em aberto no momento em que esses testes foram escritos, então
  não foi possível confirmar os locators reais da tela de pagamento (Pix copia e cola,
  código de barras, QR code) nem do download da conta em aberto. Os testes pulam
  (`SKIP`) automaticamente enquanto não houver conta em aberto; a lógica de validação
  ainda precisa ser implementada e verificada contra a tela real quando houver.
- **Persistência de e-mail inválido**: `dados_cadastrais.robot` inclui uma validação via
  Salesforce especificamente porque, durante o desenvolvimento destes testes, uma
  tentativa de e-mail inválido chegou a persistir no Contact mesmo exibindo a mensagem
  de erro na tela — o que derrubou o login da conta de teste. Se você tocar nesse teste,
  não remova essa validação.

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

#### ⚠️ Limitação conhecida: ambiente do Salesforce x ambiente do app

O `SALESFORCE_AUTH_URL` atual aponta para o ambiente de **homolog**. O app
mobile em teste (versão **BETA**) consulta o ambiente de **produção**. Isso
significa que os testes que cruzam dados do app com o Salesforce
(`fatura_salesforce.robot`, `contas_unificacao.robot`) podem acusar
divergência de dados mesmo quando não há bug — o dado em si é diferente
entre os dois ambientes, não desatualizado.

Para validar esses testes de fato contra a mesma fonte que o app usa, aponte
`SALESFORCE_AUTH_URL`/`SALESFORCE_CLIENT_ID`/`SALESFORCE_CLIENT_SECRET` para
uma Connected App do ambiente de **produção** (assim que o app sair do BETA
e/ou tivermos acesso). Até lá, uma divergência nesses testes não deve ser
tratada como bug confirmado sem antes conferir o ambiente.
