*** Settings ***
Documentation    Keywords do Portal do Titular (login, popup de indicação, dados cadastrais).
Library          Browser
Library          BuiltIn
Library          Collections
Library          String
Library          FakerLibrary    locale=pt_BR
Resource         salesforce-keywords.resource

*** Keywords ***
REALIZAR LOGIN PORTAL DO TITULAR
    [Arguments]    ${email}    ${password}

    # Indexado em [1]: o locator também casa com o botão "Entrar" do modal de
    # login (presente e oculto no DOM antes mesmo de o modal abrir), o que
    # viola o strict mode do Playwright se não for desambiguado.
    Wait For Elements State    (//*[contains(text(),'Entrar')])[1]    visible    10s
    Click    (//*[contains(text(),'Entrar')])[1]

    Wait For Elements State    //input[@type='email']    visible    10s
    Fill Text    //input[@type='email']    ${email}

    Wait For Elements State    //input[@type='password']    visible    10s
    Fill Secret    //input[@type='password']    $password

    Wait For Elements State    (//div[contains(text(),'Entrar')])[last()]    visible    10s
    Click    (//div[contains(text(),'Entrar')])[last()]

PULAR ETAPA DE SALVAR ACESSO
    [Documentation]    A tela "Deseja salvar seus dados de acesso?" é condicional —
    ...    confirmado em execuções reais em 2026-08-20: apareceu em uma rodada e
    ...    não apareceu na rodada seguinte, para a mesma conta (provavelmente
    ...    depende de um estado já salvo na conta desde a primeira vez que se
    ...    clica em "Pular"/"Salvar"). Por isso esperamos por um tempo curto e
    ...    seguimos o fluxo normalmente se ela não aparecer.
    ${apareceu}=    Run Keyword And Return Status
    ...    Wait For Elements State    text=Deseja salvar seus dados de acesso?    visible    5s

    IF    ${apareceu}
        Click    (//div[contains(text(),'Pular')])[last()]
    END

LOGIN NO PORTAL DO TITULAR
    [Documentation]    Fluxo comum a todos os testes: autentica e pula a tela de
    ...    "salvar dados de acesso". Usar como Test Setup da suíte, após ACESSAR PAGINA.
    [Arguments]    ${email}    ${password}
    REALIZAR LOGIN PORTAL DO TITULAR    ${email}    ${password}
    PULAR ETAPA DE SALVAR ACESSO

ENCERRAR TESTE PORTAL DO TITULAR
    [Documentation]    Fecha todos os browsers ao final do teste, mesmo em caso de
    ...    falha. Usar como Test Teardown da suíte.
    Run Keyword And Ignore Error    Close Browser    ALL

VALIDAR BANNER INDICACAO
    [Documentation]    O convite para indicação deixou de ser um popup e hoje é um
    ...    banner fixo na home ("SUA INDICAÇÃO VALE PIX SEM LIMITES!"). O banner
    ...    inteiro (título + botão "Quero indicar") é UMA ÚNICA IMAGEM sem
    ...    alt/aria-label — confirmado via inspeção de DOM em 2026-08-20 (nenhum
    ...    texto acessível "Quero indicar"/"regulamento" existe na página; há só
    ...    a <img src="...MainBanner/adimplente..."> com cursor:pointer). Por isso
    ...    a validação é pela presença da imagem, não por texto, e não há mais um
    ...    botão de "regulamento" separado para validar.
    Wait For Elements State    //img[contains(@src,'MainBanner')]    visible    10s

CLICAR NO BANNER INDICACAO
    [Documentation]    Clica no banner de indicação (imagem) e confirma que uma
    ...    nova aba foi aberta (o banner leva a um link externo).
    VALIDAR BANNER INDICACAO
    @{paginas_antes}=    Get Page Ids
    Click    //img[contains(@src,'MainBanner')]
    Wait Until Keyword Succeeds    5s    500ms    NOVA PAGINA DEVE ESTAR ABERTA    ${paginas_antes}

NOVA PAGINA DEVE ESTAR ABERTA
    [Arguments]    ${paginas_antes}
    @{paginas_depois}=    Get Page Ids
    ${qtd_antes}=    Get Length    ${paginas_antes}
    ${qtd_depois}=    Get Length    ${paginas_depois}
    Should Be True    ${qtd_depois} > ${qtd_antes}    Nenhuma aba nova foi aberta.

ACESSAR DADOS CADASTRAIS
    Wait For Elements State    //div[contains(text(),'Perfil')]    visible    10s
    Click    //div[contains(text(),'Perfil')]

    Wait For Elements State    //div[contains(text(),'Dados cadastrais')]    visible    10s
    Click    //div[contains(text(),'Dados cadastrais')]

ALTERAR EMAIL DO TITULAR
    [Arguments]    ${novo_email}
    Wait For Elements State    //input[@placeholder='Digite seu e-mail']    visible    10s
    Click    //input[@placeholder='Digite seu e-mail']
    Keyboard Key    press    Control+a
    Keyboard Key    press    Backspace
    Fill Text    //input[@type='email']    ${novo_email}

CLICAR EM ATUALIZAR
    [Documentation]    Clica em "Atualizar", abrindo o modal de confirmação
    ...    "Tem certeza?". Isso acontece mesmo com e-mail em formato inválido —
    ...    confirmado via inspeção em 2026-08-20: a mensagem "Digite um e-mail
    ...    válido" só é exibida DEPOIS de confirmar em "Tem certeza?", nunca
    ...    antes. Portanto CONFIRMAR ATUALIZACAO é sempre necessário, tanto no
    ...    fluxo de sucesso quanto no de erro.
    Click    //div[contains(text(),'Atualizar')]

CONFIRMAR ATUALIZACAO
    Wait For Elements State    //div[contains(text(),'Tem certeza?')]    visible    10s
    Click    //div[contains(text(),'Tem certeza?')]

VALIDAR MENSAGEM DE SUCESSO NA ATUALIZACAO
    Wait For Elements State    //div[contains(text(),'Os dados foram atualizados com sucesso!')]    visible    10s
    Wait For Elements State    //div[contains(text(),'Entendi')]    visible    10s
    Click    //div[contains(text(),'Entendi')]

VALIDAR MENSAGEM DE ERRO NA ATUALIZACAO
    Wait For Elements State    //div[contains(text(),'Digite um e-mail válido')]    visible    10s
    Click    //div[contains(text(),'Cancelar')]

VALIDAR EMAIL DO TITULAR NO SALESFORCE
    [Documentation]
    ...    Confirma, via API, que o e-mail exibido como atualizado no portal
    ...    realmente persistiu no Contact do Salesforce localizado pelo CPF.
    ...
    ...    Encapsulado em "Wait Until Keyword Succeeds" porque a sincronização
    ...    portal -> Salesforce pode não ser instantânea; ajustar o timeout
    ...    abaixo (atualmente 20s/2s) conforme a latência real observada.
    ...
    ...    Assim como no Portal de Parceiros, pode existir mais de um Contact
    ...    para o mesmo CPF: considera-se validado se QUALQUER UM dos registros
    ...    retornados tiver o e-mail esperado.
    [Arguments]    ${cpf}    ${email_esperado}

    Wait Until Keyword Succeeds    20s    2s
    ...    EMAIL DO TITULAR DEVE CONFERIR NO SALESFORCE    ${cpf}    ${email_esperado}

EMAIL DO TITULAR DEVE CONFERIR NO SALESFORCE
    [Arguments]    ${cpf}    ${email_esperado}

    @{contatos}=    BUSCAR CONTATO POR CPF    ${cpf}

    ${encontrado}=    Set Variable    ${False}
    @{emails_encontrados}=    Create List

    FOR    ${contato}    IN    @{contatos}
        ${email_salesforce}=    Set Variable    ${contato}[Email]
        Append To List    ${emails_encontrados}    ${email_salesforce}

        ${confere}=    Run Keyword And Return Status
        ...    Should Be Equal As Strings
        ...    ${email_esperado}
        ...    ${email_salesforce}
        ...    ignore_case=True

        IF    ${confere}
            ${encontrado}=    Set Variable    ${True}
            BREAK
        END
    END

    Should Be True    ${encontrado}
    ...    E-mail não confere no Salesforce. Esperado "${email_esperado}", encontrado: ${emails_encontrados}

    Log To Console    ✓ E-mail validado no Salesforce: ${email_esperado}

GERAR EMAIL DE TESTE
    [Documentation]    Gera um e-mail fake (via Faker) para usar como "novo e-mail"
    ...    no teste de atualização com sucesso, evitando reutilizar sempre o
    ...    mesmo valor entre execuções.
    ${email}=    FakerLibrary.Email
    RETURN    ${email}

GERAR EMAIL INVALIDO DE TESTE
    [Documentation]    Gera um e-mail sintaticamente inválido (sem "@") a partir de
    ...    um e-mail fake, para o teste de rejeição de formato inválido.
    ${email_base}=    FakerLibrary.Email
    ${email_invalido}=    Replace String    ${email_base}    @    ${EMPTY}
    RETURN    ${email_invalido}
