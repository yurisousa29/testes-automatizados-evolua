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
- `EMAIL_PORTAL_TITULAR` / `PASSWORD_PORTAL_TITULAR` — credenciais de uma conta de teste PF de
  **Minas Gerais**
- `CPF_TITULAR` — CPF (com ou sem formatação) do titular usado para login, necessário para
  localizar o Contact correspondente no Salesforce e validar que a alteração de e-mail persistiu
- `PORTAL_EMAIL_TESTE` — opcional, e-mail usado no teste de alteração cadastral com sucesso
  (tem um default gerado por Faker se não definida)
- `EMAIL_PORTAL_TITULAR_EXPANSAO` / `PASSWORD_PORTAL_TITULAR_EXPANSAO` — credenciais de uma conta
  de teste PF de **expansão** (qualquer estado fora de MG — o comportamento é o mesmo entre eles,
  confirmado em 2026-08-28), com pelo menos 2 CPF/CNPJ vinculados e pelo menos 1 deles com fatura
  em aberto
- `CPF_TITULAR_EXPANSAO` — reservado para uma futura validação via Salesforce equivalente à de
  `dados_cadastrais.robot`, ainda não implementada para o segmento de expansão

#### Segmentos: Minas Gerais x Expansão

O Portal do Titular tem dois comportamentos de conta bem diferentes, cobertos por arquivos
separados (mesmo backend, resource de keywords compartilhado):

- **Minas Gerais** (`EMAIL_PORTAL_TITULAR`): um único CPF/CNPJ e uma única instalação por login,
  conta unificada mostrando só a fatura da Evolua.
- **Expansão** (`EMAIL_PORTAL_TITULAR_EXPANSAO`, arquivos `expansao_*.robot`): a distribuidora
  local emite conta própria, separada da Evolua, mesmo em conta "unificada" — o portal oferece um
  link dedicado para baixar essa segunda conta em PDF ("Visualizar conta da `<distribuidora>`"), e
  o modal de pagamento avisa para não pagar as duas (duplicidade). Login pode pedir seleção de
  CPF/CNPJ vinculado ("Com qual você deseja seguir?") quando há mais de um vínculo na conta, com
  um seletor "Trocar Perfil" para alternar depois. Um mesmo perfil pode ter várias instalações
  vinculadas (uma conta de teste tinha 6, confirmado em 2026-08-28) — `OBTER NUMERO DA INSTALACAO`
  sempre pega a primeira da lista.

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
| `contas_pagamento.robot` | opções de pagamento (Pix copia e cola, código de barras, QR code) |
| `contas_encaminhar.robot` | download do PDF da conta Evolua ("Baixar conta") |
| `indicacao_tab_indicar_amigo.robot` | formulário "Indique um amigo" (habilitação, máscara, validação) |
| `indicacao_tab_compartilhar.robot` | botão "Compartilhar" da aba Indicação |
| `indicacao_tab_faq.robot` | "Como funciona o Rede Evolua+?" |
| `indicacao_tab_chave_pix.robot` | navegação até "Alterar chave pix" (não submete dados) |
| `expansao_login.robot` | seleção de CPF/CNPJ vinculado no login + "Trocar Perfil" |
| `expansao_contas.robot` | download do PDF da distribuidora + aviso de duplicidade de pagamento + texto do banner de unificação |

`contas_pagamento.robot` e `contas_encaminhar.robot` pulam (`SKIP`) automaticamente quando a
conta configurada não tem fatura em aberto no momento — isso é esperado para MG na maioria das
execuções; a lógica em si já foi verificada contra uma conta de expansão com fatura real.

#### ⚠️ Limitações conhecidas

- **Aba "Consumo" da 2ª via** (2026-08-20): ficou travada num spinner infinito em execuções
  manuais contra homologação. `IR PARA ABA CONSUMO` só confirma a navegação, sem validar os
  valores exibidos — investigar antes de fortalecer essa validação.
- **Persistência de e-mail inválido**: `dados_cadastrais.robot` inclui uma validação via
  Salesforce especificamente porque, durante o desenvolvimento destes testes, uma
  tentativa de e-mail inválido chegou a persistir no Contact mesmo exibindo a mensagem
  de erro na tela — o que derrubou o login da conta de teste. Se você tocar nesse teste,
  não remova essa validação.
- **Tela "Dados cadastrais" muda com frequência** (2026-08-28): já foi um campo de e-mail direto,
  hoje é uma lista de contatos colapsados (cada um com nome/e-mail/telefone, expandidos por um
  botão sem ícone/svg identificável — ver `ACESSAR DADOS CADASTRAIS` no resource). Se este teste
  voltar a quebrar em "aguardando input de e-mail", é provável que o layout tenha mudado de novo —
  inspecionar a tela real antes de tentar corrigir o locator às cegas.
- **Regex em `Evaluate`/`Should Match Regexp` dentro deste resource**: sempre usar `\\d`, `\\s`,
  `\\w` (barra dupla) no código-fonte, nunca `\d`/`\s`/`\w` (barra simples) — o Robot Framework
  remove uma camada de escape antes do valor chegar no regex, então uma barra simples vira a letra
  solta (`\d` → `d`) e o regex nunca casa. Já causou bugs silenciosos em pelo menos 3 keywords
  diferentes neste arquivo.

### Finder (`src/tests/finder`)

Cadastro de empresas parceiras que vendem o produto Evolua e recebem retorno
financeiro ("Finder"). Existem dois caminhos de cadastro, ambos usando o
**mesmo formulário de 3 etapas** (Empresa → Endereço → Financeiro) e o
**mesmo endpoint** (`POST /api/v1/Finder/Register`):

- **Deslogado** (público, sem conta): `https://parceiro-dev.evoluaenergia.com.br/register-finder-forms/`
- **Logado**, dentro do Portal dos Parceiros: `.../register-finder/` — usa as
  mesmas variáveis `URL_PORTAL` / `EMAIL_PORTAL` / `PASSWORD_PORTAL` do Portal
  de Parceiros. Tem um botão extra, "Abrir lista de CNAE's disponíveis para
  cadastro", que o caminho deslogado não tem.

#### ⚠️ Achados importantes (2026-09-10)

- **Sucesso sem nenhum feedback visual**: ao concluir o cadastro com sucesso
  (a API retorna 201 com `accountId`/`contactId`, e um Account + Contact são
  criados de verdade no Salesforce), a tela **não mostra nenhuma confirmação**
  — o formulário simplesmente volta ao estado vazio da etapa "Empresa" em
  silêncio. Por isso os testes de sucesso validam a resposta da API + a
  criação real do Account/Contact no Salesforce (`VALIDAR CADASTRO FINDER
  CRIADO NO SALESFORCE`), não uma mensagem de tela. Já o erro de duplicidade
  (e-mail/CNPJ já cadastrado) **é exibido normalmente** (banner vermelho no
  topo: "Dados já pertencentes a um contato Finder.").
- **Navegação direta para o caminho logado perde a sessão**: acessar
  `.../register-finder/` via URL direta (`Go To`) depois de logar redireciona
  de volta para a tela de login — a sessão não se mantém em navegação direta.
  Pode estar relacionado a um bug já conhecido pelo time: o botão que deveria
  levar o usuário logado até o Finder não está aparecendo no portal (se
  existisse como link interno, talvez preservasse a sessão por não recarregar
  a página inteira). Os testes do caminho logado pulam (`SKIP`) com essa
  mensagem enquanto isso não for esclarecido — ver `IR PARA CADASTRO FINDER
  LOGADO` no resource. Se você souber de outro caminho de navegação interna
  até o Finder, atualize essa keyword para usá-lo em vez de `Go To`.

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
