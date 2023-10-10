# UFSC3D NPCs Utils

Este repositório contém utilidades para os NPCs do servidor OpenSimulator UFSC3D.  
Consiste em um webapp/API Flask capaz de calcular rotas e simular um chatbot.  
A pasta `ufsc3d` contém scripts e notecards para os NPCs dentro do mundo virtual, ajustados para utilizar a API.  
A pasta `webapp` contém o código da API.

## Requisitos

É necessário ter Python >= 3.6.9 e sua versão correspondente de pip instalados, então rodar `pip install -r webapp/requirements.txt`.  
Também é necessário ter as chaves da API para o chatbot gravadas nas variáveis de ambiente `OPENAI_API_KEY` e `PAWANS_API_KEY`.  
As instruções para criação dessas chaves podem ser encontradas [aqui](https://platform.openai.com/account/api-keys) e [aqui](https://github.com/PawanOsman/ChatGPT), respectivamente.

## Uso

Para gerenciamento da API, existem dois scripts de conveniência:

- `run-webapp.sh`: levanta a API escutando chamadas em 0.0.0.0, na porta 8080, em um servidor [gunicorn](https://gunicorn.org/).
- `down-webapp.sh`: derruba o servidor gunicorn da porta 8080.

## Documentação

A API disponibiliza uma documentação para cada rota no endpoint `/apidocs`. Essa documentação é gerada pelo [flasgger](https://github.com/flasgger/flasgger) através das descrições fornecidas em `webapp/apidocs/`.
