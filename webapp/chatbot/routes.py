from flask import Blueprint, request
from flasgger import swag_from
from .chatbot import chat

router = Blueprint('chatbot', __name__,)
docs_path = '../apidocs/chatbot/'

@router.route('/chat', methods=['POST'])
@swag_from(docs_path + 'chat.yml')
def route_chat():
    try:
        user_prompt = request.form.get('user_prompt', type=str)
        bot_prompt = request.form.get('bot_premisse', type=str, default=None)
        use_openai = request.form.get('use_openai', type=bool, default=False)
        return chat(user_prompt, use_openai, system_prompt=bot_prompt)
    except Exception as e:
        print(e)