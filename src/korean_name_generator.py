from openai import OpenAI
from clients.openai_client import get_openai_client

client = get_openai_client()


# ------------------------------
# 2. 한국 이름 생성 함수
# ------------------------------
def generate_similar_korean_name(input_name: str, client: OpenAI = None) -> str:
    """
    외국 이름을 한국식으로 자연스럽게 변형하여 발음과 유사한 한국 이름과 영어 발음을 반환.
    
    Args:
        input_name (str): 사용자 입력 이름 (영어, 중국어, 일본어 등 가능)
        client (OpenAI, optional): OpenAI API 클라이언트. 지정하지 않으면 get_openai_client() 사용
    
    Returns:
        str: "(한국이름, 영어발음)" 형태의 문자열
    """
    if client is None:
        client = get_openai_client()

    system_prompt = """
당신의 역할은 '외국 이름을 한국식으로 자연스럽게 변형하여 발음과 유사한 한국 이름 하나를 추천'하는 것입니다.

규칙:
1. 입력 이름의 발음을 그대로 옮기지 말고, 한국식 음운에 맞게 자연스럽게 수정. 
   (예: Donald Trump -> 도널드(x), 두말돈)
2. 출력은 무조건 한 개의 한국 이름과 영어 발음만 (예: (홍록기, Hong-Loggi))
3. 설명, 부연설명, 따옴표, 접두사 없이 (이름, 영어발음)만 출력
4. 한국식 실존 느낌이 나는 2~4음절 이름을 추천.
5. 영어, 중국어, 일본어 등 어떤 언어 이름이 들어와도 발음을 기반으로 자연스러운 한국식 이름 하나를 생성.
"""

    response = client.chat.completions.create(
        model="gpt-4o", 
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": input_name}
        ],
        max_tokens=50,
        temperature=0.7
    )

    return response.choices[0].message.content.strip()