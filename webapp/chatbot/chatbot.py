from os import environ
from requests import post

# Chaves devem ser guardadas em variáveis de ambiente
OPENAI_API_KEY = environ['OPENAI_API_KEY']
PAWANS_API_KEY = environ['PAWANS_API_KEY']

def chat(user_prompt, use_openai, system_prompt=None):
    """
    Simula um chatbot, respondendo a um prompt enviado por um usuário, seguindo uma premissa (system_prompt).\n
    Envia uma requisição para os respectivos endpoints de compleção de chat.\n
    Parametros:
        user_prompt: str - A mensagem que o usuário final quer mandar ao Chatbot\n
        use_openai: bool - True para utilizar o endpoint da OpenAI (requer uma conta com créditos),
            False para utilizar o endpoint de https://github.com/PawanOsman/ChatGPT\n
        system_prompt: str (opcional) - A premissa que o bot deve seguir. Se não for passado, o bot vai "fingir" ser um assistente da UFSC
            e responder a mensagem do usuário de forma curta\n
    Retorna uma string com a resposta do bot
    """

    if use_openai:
        api_endpoint = 'https://api.openai.com/v1/chat/completions'
        ai_model = 'gpt-3.5-turbo'
        api_key = OPENAI_API_KEY
    else:
        api_endpoint = 'https://api.pawan.krd/v1/chat/completions'
        ai_model = 'pai-001-light-beta'
        api_key = PAWANS_API_KEY

    if not system_prompt:
        system_prompt = "Você é um assistente na Universidade Federal de Santa Catarina (UFSC) - Campus Florianópolis/Trindade.\
            Você será providenciado com uma pergunta ou fala qualquer de um estudante dessa universidade.\
            Responda de acordo e de maneira curta, concisa."
    
    headers = {
        'Authorization': 'Bearer ' + api_key,
        'Content-Type': 'application/json'
    }

    body = {
        'model': ai_model,
        'stream': False,
        'messages': [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ]
    }

    try:
        response = post(api_endpoint, headers=headers, json=body)
        if response.ok:
            return response.json()['choices'][0]['message']['content']
        return 'Erro ao contatar o serviço de chatbot. Contate o administrador do sistema.'
    except Exception as e:
        print('3')
        return 'Desculpe. Não consegui processar sua mensagem. Reformule-a e/ou contate o administrador do sistema.'