*** Settings ***
Documentation    Teste de fumaça: confirma que o app abre corretamente no emulador.
Resource    ../../keywords/app-mobile-keywords.resource
Test Teardown    FECHAR APLICATIVO

*** Test Cases ***
APP DEVE ABRIR COM SUCESSO
    ABRIR APLICATIVO EVOLUA
    Sleep    3s
