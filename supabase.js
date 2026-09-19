/* =======================================================
   Supabase 연결 설정
   - 이 파일 하나에 접속 정보를 모아둡니다.
   - 쓰는 방법: 각 페이지에서 아래 두 줄을 순서대로 불러옵니다.

       <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
       <script src="supabase.js"></script>

   - 그 뒤로는 어느 페이지에서든 db 를 바로 쓸 수 있습니다.

       // 넣기
       await db.from("테이블이름").insert({ 이름: "홍길동" });

       // 읽기
       const { data, error } = await db.from("테이블이름").select("*");
   ======================================================= */

/* ----- 접속 정보 -----
   아래 키는 publishable(공개용) 키입니다.
   웹 화면에 드러나도 되도록 만들어진 키라서 이 파일에 적어 둡니다.

   ※ 절대 여기에 적으면 안 되는 것:
      secret 키 / service_role 키
      이 둘은 모든 자료를 지울 수 있는 열쇠입니다.
      서버에서만 쓰고, 이런 파일에는 넣지 마세요.
*/
const SUPABASE_URL = "https://kwxvpayepbbtcrpitrti.supabase.co";
const SUPABASE_KEY = "sb_publishable_8KRPyMcd2WFIGqU-tr3DsA_wu-Oe5jn";

/* ----- 연결 만들기 ----- */
// 라이브러리가 먼저 불러와졌는지 확인합니다
var db = null;

if (window.supabase && window.supabase.createClient) {
  db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
} else {
  console.error(
    "[Supabase] 라이브러리를 찾지 못했습니다.\n" +
    "supabase.js 보다 먼저 아래 줄이 있어야 합니다.\n" +
    '<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>'
  );
}

/* ----- 연결이 잘 됐는지 확인하기 -----
   브라우저에서 F12 를 눌러 콘솔 창에 아래를 입력하면
   연결 상태를 확인할 수 있습니다.

       checkDB()
*/
async function checkDB() {
  if (!db) {
    console.error("[Supabase] 연결이 만들어지지 않았습니다.");
    return false;
  }

  try {
    // 로그인 상태를 물어보는 가장 가벼운 요청으로 확인합니다
    const { error } = await db.auth.getSession();

    if (error) {
      console.error("[Supabase] 연결 실패:", error.message);
      return false;
    }

    console.log("[Supabase] 연결 정상 ✓");
    console.log("  주소:", SUPABASE_URL);
    console.log("  테이블을 만드시려면 supabase.com 의 SQL Editor 를 쓰세요.");
    return true;

  } catch (e) {
    console.error("[Supabase] 연결 실패:", e.message);
    return false;
  }
}

// 페이지가 열리면 한 번 확인해서 콘솔에 남겨둡니다
if (db) checkDB();

/* =======================================================
   머리말에 로그인 상태를 그립니다
   - 페이지에 <div class="auth" id="authBox"></div> 가 있으면
     그 안에 자동으로 채워집니다.
   - 로그인 전: 로그인 / 회원가입 단추
   - 로그인 후: 이름 / 로그아웃 단추
   ======================================================= */
async function drawAuth() {
  var box = document.getElementById("authBox");
  if (!box) return;          // 이 칸이 없는 페이지는 건너뜁니다

  // 연결이 안 됐으면 로그인 단추만 보여줍니다
  if (!db) {
    box.innerHTML = '<a class="pill" href="login.html">로그인</a>'
                  + '<a class="pill" href="join.html">회원가입</a>';
    return;
  }

  var user = null;
  try {
    const { data } = await db.auth.getSession();
    if (data && data.session) user = data.session.user;
  } catch (e) {
    // 확인하지 못하면 로그인 전으로 둡니다
  }

  if (user) {
    // 가입할 때 넣은 이름이 있으면 그 이름을, 없으면 '회원'으로 부릅니다
    var name = (user.user_metadata && user.user_metadata.name)
             ? user.user_metadata.name : "회원";

    box.innerHTML = '<span class="pill me">' + name + '님</span>'
                  + '<button class="pill out" onclick="siteLogout()">로그아웃</button>';
  } else {
    box.innerHTML = '<a class="pill" href="login.html">로그인</a>'
                  + '<a class="pill" href="join.html">회원가입</a>';
  }

  // 메뉴 줄의 '회원가입' 도 로그인하면 감춥니다
  // (이미 가입한 사람에게는 필요 없는 메뉴입니다)
  hideJoinMenu(user ? true : false);
}

/* ----- 메뉴 줄의 회원가입을 감추거나 다시 보이게 합니다 ----- */
function hideJoinMenu(hide) {
  var links = document.querySelectorAll('nav.site a[href="join.html"]');

  for (var i = 0; i < links.length; i++) {
    // nav 의 글자는 inline-block 이라 display 를 직접 바꿔줍니다
    links[i].style.display = hide ? "none" : "";
  }
}

/* ----- 어느 페이지에서든 로그아웃할 수 있습니다 ----- */
async function siteLogout() {
  if (db) await db.auth.signOut();
  drawAuth();                // 표시를 로그인 전으로 되돌립니다

  // 로그인 페이지에 있었다면 그 화면도 함께 되돌립니다
  if (typeof logOut === "function" && document.getElementById("signed")) {
    document.getElementById("formArea").className = "form-area";
    document.getElementById("signed").className   = "signed";
  }
}

// 화면이 다 그려지면 로그인 상태를 표시합니다
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", drawAuth);
} else {
  drawAuth();
}
