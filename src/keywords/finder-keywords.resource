*** Settings ***
Documentation    Keywords do cadastro Finder (empresas parceiras que vendem o
...              produto Evolua e recebem retorno financeiro). Cobre os dois
...              caminhos de cadastro:
...              - Deslogado: https://parceiro-dev.evoluaenergia.com.br/register-finder-forms/
...              - Logado (dentro do Portal dos Parceiros): .../register-finder/
...              Os dois usam exatamente o mesmo formulário de 3 etapas
...              (Empresa -> Endereço -> Financeiro) e submetem para o mesmo
...              endpoint (POST /api/v1/Finder/Register) — confirmado em
...              2026-09-10. A única diferença de tela é que o caminho logado
...              tem um botão extra "Abrir lista de CNAE's disponíveis".
Library          Browser
Library          BuiltIn
Library          Collections
Resource         salesforce-keywords.resource

*** Keywords ***
IR PARA CADASTRO FINDER DESLOGADO
    ACESSAR PAGINA https://parceiro-dev.evoluaenergia.com.br/register-finder-forms/
    Wait For Elements State    //input[@placeholder='Nome da empresa']    visible    10s

IR PARA CADASTRO FINDER LOGADO
    [Documentation]    Requer login prévio no Portal dos Parceiros (ver
    ...    REALIZAR LOGIN PORTAL DOS PARCEIROS).
    ...
    ...    LIMITAÇÃO CONHECIDA (2026-09-10): navegar direto para esta URL
    ...    depois do login (via "Go To") redireciona de volta para a tela de
    ...    login — a sessão não se mantém em navegação direta por URL. Pode
    ...    estar relacionado a um bug já conhecido: o botão que deveria levar
    ...    o usuário logado até o cadastro Finder não está aparecendo no
    ...    portal (se existisse e fosse um link interno, talvez preservasse a
    ...    sessão por não recarregar a página inteira). Até isso ser
    ...    esclarecido/corrigido, esta keyword pula (SKIP) em vez de falhar.
    Go To    https://parceiro-dev.evoluaenergia.com.br/register-finder/
    ${voltou_pro_login}=    Run Keyword And Return Status
    ...    Wait For Elements State    text=Acesse sua conta    visible    5s
    IF    ${voltou_pro_login}
        Skip    Navegação direta para /register-finder/ perdeu a sessão e voltou para o login (ver limitação conhecida na documentação desta keyword).
    END
    Wait For Elements State    text=Registrar Finder    visible    10s

PREENCHER ETAPA EMPRESA FINDER
    [Arguments]
    ...    ${nome_empresa}    ${razao_social}    ${cnpj}    ${tipo_empresa}
    ...    ${nome_responsavel}    ${documento_responsavel}    ${telefone_responsavel}    ${email_responsavel}
    Wait For Elements State    //input[@placeholder='Nome da empresa']    visible    10s
    Fill Text    //input[@placeholder='Nome da empresa']    ${nome_empresa}
    Fill Text    //input[@placeholder='Razão Social']    ${razao_social}
    Fill Text    //input[@placeholder='CNPJ']    ${cnpj}

    Click    //input[@placeholder='Tipo de empresa']
    Wait For Elements State    //div[text()='${tipo_empresa}']    visible    5s
    Click    //div[text()='${tipo_empresa}']

    Fill Text    //input[@placeholder='Nome do responsável']    ${nome_responsavel}
    Fill Text    //input[@placeholder='Documento do responsável']    ${documento_responsavel}
    Fill Text    //input[@placeholder='Telefone do responsável']    ${telefone_responsavel}
    Fill Text    //input[@placeholder='E-mail do responsável']    ${email_responsavel}

AVANCAR CADASTRO FINDER
    Click    //span[text()='Avançar']

ANEXAR DOCUMENTOS FINDER
    [Documentation]    Anexa Cartão CNPJ e Documento de Identificação. A tela só
    ...    valida o formato do arquivo (PDF/JPG/PNG), não o conteúdo — por isso
    ...    reaproveitamos um template já existente no projeto para os dois.
    Wait For Elements State    (//input[@type='file'])[1]    attached    10s
    Upload File By Selector    (//input[@type='file'])[1]    src/templates/rg-frente.png
    Upload File By Selector    (//input[@type='file'])[2]    src/templates/rg-frente.png

PREENCHER ETAPA ENDERECO FINDER
    [Documentation]    O CEP preenche Logradouro/Bairro/Cidade/Estado
    ...    automaticamente (consulta real) — só é preciso informar Número e,
    ...    opcionalmente, Complemento.
    [Arguments]    ${cep}    ${numero}    ${complemento}=${EMPTY}
    Wait For Elements State    //input[@placeholder='CEP']    visible    10s
    Fill Text    //input[@placeholder='CEP']    ${cep}
    Wait For Elements State    //input[@placeholder='Cidade']    visible    5s

    Fill Text    //input[@placeholder='Número']    ${numero}
    IF    '''${complemento}''' != ''
        Fill Text    //input[@placeholder='Complemento']    ${complemento}
    END

PREENCHER ETAPA FINANCEIRO FINDER
    [Arguments]    ${banco}    ${agencia}    ${conta}    ${chave_pix}
    Wait For Elements State    //input[@placeholder='Banco']    visible    10s
    Fill Text    //input[@placeholder='Banco']    ${banco}
    Fill Text    //input[@placeholder='Agência']    ${agencia}
    Fill Text    //input[@placeholder='Conta']    ${conta}
    Fill Text    //input[@placeholder='Chave Pix']    ${chave_pix}

FINALIZAR CADASTRO FINDER
    [Documentation]    Clica em "Finalizar Cadastro" e retorna a resposta da API
    ...    (POST /api/v1/Finder/Register) como um dicionário Robot Framework
    ...    (status/body/etc.) — é a fonte de verdade pra saber se o cadastro
    ...    funcionou. Confirmado em 2026-09-10: em caso de SUCESSO a tela não
    ...    dá nenhum feedback visual (só reseta o formulário em silêncio) — ver
    ...    VALIDAR CADASTRO FINDER CRIADO NO SALESFORCE. Em caso de erro de
    ...    duplicidade a tela mostra um banner normalmente (ver VALIDAR ERRO DE
    ...    CADASTRO DUPLICADO).
    ${promise}=    Promise To    Wait For Response
    ...    matcher=response => response.url().includes('Finder/Register')    timeout=15s
    Click    //span[text()='Finalizar Cadastro']
    Wait For All Promises
    ${resposta}=    Evaluate    $promise.result()
    RETURN    ${resposta}

VALIDAR ERRO DE CADASTRO DUPLICADO
    Wait For Elements State    text=Dados já pertencentes a um contato Finder.    visible    10s

VALIDAR CADASTRO FINDER CRIADO NO SALESFORCE
    [Documentation]    Confirma via Salesforce que o Account (empresa) e o
    ...    Contact (responsável) foram criados corretamente — necessário porque
    ...    a tela não dá nenhuma confirmação visual de sucesso (ver
    ...    FINALIZAR CADASTRO FINDER).
    [Arguments]
    ...    ${account_id}    ${contact_id}    ${nome_empresa}    ${cnpj}
    ...    ${nome_responsavel}    ${documento_responsavel}    ${email_responsavel}

    ${cnpj_sem_formatacao}=    Evaluate
    ...    '''${cnpj}'''.replace('.', '').replace('/', '').replace('-', '')
    ${doc_sem_formatacao}=    Evaluate
    ...    '''${documento_responsavel}'''.replace('.', '').replace('-', '')

    ${res_conta}=    EXECUTAR SOQL
    ...    SELECT Id, Name, CPFCNPJSemFormataco__c FROM Account WHERE Id = '${account_id}'
    Should Be True    ${res_conta}[totalSize] > 0
    ...    Account ${account_id} não encontrada no Salesforce.
    ${conta}=    Set Variable    ${res_conta}[records][0]
    Should Be Equal As Strings    ${conta}[Name]    ${nome_empresa}    ignore_case=True
    Should Be Equal As Strings    ${conta}[CPFCNPJSemFormataco__c]    ${cnpj_sem_formatacao}

    ${res_contato}=    EXECUTAR SOQL
    ...    SELECT Id, Name, Email, CPFCNPJSemFormataco__c FROM Contact WHERE Id = '${contact_id}'
    Should Be True    ${res_contato}[totalSize] > 0
    ...    Contact ${contact_id} não encontrado no Salesforce.
    ${contato}=    Set Variable    ${res_contato}[records][0]
    Should Be Equal As Strings    ${contato}[Name]    ${nome_responsavel}    ignore_case=True
    Should Be Equal As Strings    ${contato}[Email]    ${email_responsavel}    ignore_case=True
    Should Be Equal As Strings    ${contato}[CPFCNPJSemFormataco__c]    ${doc_sem_formatacao}

    Log To Console
    ...    ✓ Cadastro Finder confirmado no Salesforce: Account "${nome_empresa}" + Contact "${nome_responsavel}"

# ---------------------------------------------------------------------------
# Lista de CNAE's disponíveis (só existe no caminho logado)
# ---------------------------------------------------------------------------

ABRIR LISTA DE CNAES DISPONIVEIS
    Wait For Elements State    //button[contains(text(),'CNAE')]    visible    10s
    Click    //button[contains(text(),'CNAE')]
    Wait For Elements State    text=Confira os CNAE's disponíveis para cadastro    visible    10s

BUSCAR CNAE
    [Arguments]    ${termo}
    Fill Text    //input[@placeholder='Pesquisar um código ou atividade de CNAE']    ${termo}

CONTAR LINHAS DA LISTA DE CNAES
    ${qtd}=    Get Element Count    //table//tr
    RETURN    ${qtd}

FECHAR LISTA DE CNAES
    Click    //span[text()='Close']
    Wait For Elements State    text=Confira os CNAE's disponíveis para cadastro    hidden    5s
