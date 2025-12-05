import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()  # 필요 시 환경변수 로드

def get_openai_client() -> OpenAI:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("환경변수 OPENAI_API_KEY를 설정해주세요.")
    return OpenAI(api_key=api_key)