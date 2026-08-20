*** Settings ***
Library      ../API/salesforce_keywords.py    WITH NAME    SalesforceAPI
Variables    ../../load_env.py


*** Keywords ***
CONECTAR SALESFORCE
    SalesforceAPI.Conectar Salesforce


BUSCAR LEADS POR CPF
    [Arguments]    ${cpf}

    ${resultado}=    SalesforceAPI.Buscar Leads Por CPF    ${cpf}

    RETURN    ${resultado}


BUSCAR CONTRATOS POR CPF
    [Arguments]    ${cpf}

    ${resultado}=    SalesforceAPI.Buscar Contratos Por CPF    ${cpf}

    RETURN    ${resultado}


BUSCAR CONTATO POR CPF
    [Arguments]    ${cpf}

    ${resultado}=    SalesforceAPI.Buscar Contato Por CPF    ${cpf}

    RETURN    ${resultado}


EXECUTAR SOQL
    [Arguments]    ${soql}

    ${resultado}=    SalesforceAPI.Executar Soql    ${soql}

    RETURN    ${resultado}