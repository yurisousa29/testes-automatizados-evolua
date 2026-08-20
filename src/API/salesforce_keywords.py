import os

from salesforce_client import SalesforceClient


ROBOT_LIBRARY_SCOPE = "GLOBAL"

_client = None


def conectar_salesforce():
    global _client

    client_id = os.getenv("SALESFORCE_CLIENT_ID")
    client_secret = os.getenv("SALESFORCE_CLIENT_SECRET")
    auth_url = os.getenv("SALESFORCE_AUTH_URL")

    if not client_id:
        raise ValueError(
            "Variável SALESFORCE_CLIENT_ID não encontrada."
        )

    if not client_secret:
        raise ValueError(
            "Variável SALESFORCE_CLIENT_SECRET não encontrada."
        )

    if not auth_url:
        raise ValueError(
            "Variável SALESFORCE_AUTH_URL não encontrada."
        )

    _client = SalesforceClient(
        client_id=client_id,
        client_secret=client_secret,
        auth_url=auth_url,
    )

    return True


def executar_soql(soql):
    _validar_conexao()
    return _client.query(soql)


def buscar_leads_por_cpf(cpf):
    """
    Retorna todos os Leads cadastrados para o CPF informado, ordenados do
    mais recente para o mais antigo.

    Pode haver mais de um registro: na Evolua é possível existir mais de um
    Lead para o mesmo CPF/CNPJ (ex.: um Lead é recriado após correção de
    dados de um cadastro anterior). Por isso a busca não usa LIMIT 1 e cabe
    a quem consome o resultado decidir qual(is) registro(s) são relevantes.
    """
    _validar_conexao()

    cpf_sem_formatacao = _normalizar_cpf(cpf)

    soql = f"""
        SELECT
            Id,
            Name,
            Email,
            Phone,
            Status,
            CreatedDate,
            CPFCNPJSemFormataco__c
        FROM Lead
        WHERE CPFCNPJSemFormataco__c = '{cpf_sem_formatacao}'
        ORDER BY CreatedDate DESC
    """

    resultado = _client.query(soql)
    registros = resultado.get("records", [])

    if not registros:
        raise AssertionError(
            "Nenhum Lead encontrado no Salesforce para o CPF informado."
        )

    return registros


def buscar_contato_por_cpf(cpf):
    """
    Retorna todos os Contacts cadastrados para o CPF informado, ordenados do
    mais recente para o mais antigo.

    Usado para validar o Portal do Titular (ex.: confirmar que uma alteração
    de e-mail feita no portal persistiu no Salesforce). Assim como Lead e
    Contract, pode haver mais de um Contact para o mesmo CPF.
    """
    _validar_conexao()

    cpf_sem_formatacao = _normalizar_cpf(cpf)

    soql = f"""
        SELECT
            Id,
            Name,
            Email,
            CPFSemFormataco__c
        FROM Contact
        WHERE CPFSemFormataco__c = '{cpf_sem_formatacao}'
        ORDER BY CreatedDate DESC
    """

    resultado = _client.query(soql)
    registros = resultado.get("records", [])

    if not registros:
        raise AssertionError(
            "Nenhum Contact encontrado no Salesforce para o CPF informado."
        )

    return registros


def buscar_contratos_por_cpf(cpf):
    """
    Retorna todos os Contracts (contratos) cadastrados para o CPF informado,
    ordenados do mais recente para o mais antigo.

    Assim como os Leads, um mesmo CPF/CNPJ pode ter vários contratos em
    status diferentes. Retorna a lista (possivelmente vazia); cabe a quem
    consome decidir a validação. Observação: no objeto Contract o campo de
    CPF/CNPJ é 'CPFCNPJSemFormatacao__c' (diferente do Lead, que é
    'CPFCNPJSemFormataco__c').
    """
    _validar_conexao()

    cpf_sem_formatacao = _normalizar_cpf(cpf)

    soql = f"""
        SELECT
            Id,
            Status,
            CPFCNPJSemFormatacao__c
        FROM Contract
        WHERE CPFCNPJSemFormatacao__c = '{cpf_sem_formatacao}'
        ORDER BY CreatedDate DESC
    """

    resultado = _client.query(soql)

    return resultado.get("records", [])


def _normalizar_cpf(cpf):
    cpf_sem_formatacao = (
        str(cpf)
        .replace(".", "")
        .replace("-", "")
        .replace("/", "")
        .strip()
    )

    if not cpf_sem_formatacao.isdigit():
        raise ValueError(
            "O CPF informado possui caracteres inválidos."
        )

    if len(cpf_sem_formatacao) not in (11, 14):
        raise ValueError(
            "O CPF/CNPJ informado deve possuir 11 ou 14 dígitos."
        )

    return cpf_sem_formatacao


def _validar_conexao():
    if _client is None:
        raise RuntimeError(
            "Salesforce não conectado. "
            "Execute CONECTAR SALESFORCE primeiro."
        )