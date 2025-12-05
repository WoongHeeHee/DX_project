import sqlite3
from pathlib import Path
from clients.openai_client import get_openai_client

client = get_openai_client()

# =============================
# DB 연결 / 초기화
# =============================
DB_PATH = Path(__file__).parent / "menus.db"

def init_db():
    """메뉴 DB 초기화 및 기본 메뉴 삽입"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS menus (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        )
    """)
    # 기본 메뉴 샘플
    default_menus = [
        "붕어빵", "김밥", "떡볶이", "순대", "김치전", "김치찌개", "된장찌개", "순두부찌개",
        "갈비탕", "설렁탕", "삼계탕", "비빔밥", "돌솥비빔밥", "불고기", "제육볶음", "갈비찜",
        "잡채", "오징어볶음", "닭갈비", "감자탕", "해물파전", "부추전", "파전", "계란말이",
        "튀김", "라면", "칼국수", "비빔국수", "냉면", "콩국수", "만두", "찐만두",
        "군만두", "보쌈", "족발", "삼겹살", "오리구이", "곱창구이", "양념치킨", "후라이드치킨",
        "간장치킨", "치즈닭갈비", "볶음밥", "김치볶음밥", "제육덮밥", "낙지볶음", "오징어덮밥",
        "카레라이스", "돈까스", "함박스테이크", "떡국", "만두국", "쌀국수"
    ]
    for menu in default_menus:
        try:
            cursor.execute("INSERT INTO menus(name) VALUES(?)", (menu,))
        except sqlite3.IntegrityError:
            pass  # 이미 있는 메뉴는 무시
    conn.commit()
    conn.close()

def get_all_menus():
    """DB에서 모든 메뉴 리스트 반환"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM menus")
    rows = cursor.fetchall()
    conn.close()
    return [row[0] for row in rows]

def add_menu(menu_name: str) -> bool:
    """새로운 메뉴를 DB에 추가"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("INSERT INTO menus(name) VALUES(?)", (menu_name,))
        conn.commit()
        conn.close()
        return True
    except sqlite3.IntegrityError:
        return False  # 이미 존재하는 메뉴

def remove_menu(menu_name: str) -> bool:
    """메뉴를 DB에서 제거"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM menus WHERE name = ?", (menu_name,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def search_menus(keyword: str) -> list:
    """키워드로 메뉴 검색"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM menus WHERE name LIKE ?", (f"%{keyword}%",))
    rows = cursor.fetchall()
    conn.close()
    return [row[0] for row in rows]

# =============================
# GPT-4V 멀티모달 메뉴 매칭
# =============================
def match_menu(image_url=None, user_text=None):
    """
    GPT-4V를 이용하여 메뉴 추출
    :param image_url: 이미지 URL (선택)
    :param user_text: 사용자가 입력한 음식 묘사 (선택)
    :return: menus DB 내 메뉴 이름 혹은 None
    """
    menus = get_all_menus()
    menu_list_str = ", ".join(menus)
    prompt = f"다음 메뉴 중 하나만 선택하세요: [{menu_list_str}]\n"
    if user_text:
        prompt += f"사용자 설명: \"{user_text}\"\n"
    prompt += "메뉴 이름 혹은 None 만 출력하세요."

    message_content = [{"type": "text", "text": prompt}]
    if image_url:
        message_content.append({"type": "image_url", "image_url": {"url": image_url}})

    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[{"role": "user", "content": message_content}]
    )
    answer = response.choices[0].message.content.strip()
    return answer if answer in menus else None

# =============================
# 초기화 실행
# =============================
if not DB_PATH.exists():
    init_db()