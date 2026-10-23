if (response.statusCode == 200) {
final data = jsonDecode(response.body);
UserSession.instance.username = data['username'];
UserSession.instance.token = data['token'];


if (!mounted) return;
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => MainShell()),
);
} else {
final data = jsonDecode(response.body);
setState(() => _error = data['detail'] ?? 'Something went wrong. Please try again.');
}
}catch (e) {
if (!mounted) return;
setState(() => _error = 'DEBUG ERROR: $e');                                              //Something went wrong. Please try again.
} finally {
if (mounted) setState(() => _isLoading = false);
}
}








if (response.statusCode == 200) {
final data = jsonDecode(response.body);
UserSession.instance.username = data['username'];
UserSession.instance.token =
data['token']; // add this field to UserSession

if (!mounted) return;
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => MainShell()),
);
} else {
final data = jsonDecode(response.body);
setState(() => _error = data['detail'] ?? 'Invalid email or password.');
}
} catch (e) {
if (!mounted) return;
setState(() => _error = 'DEBUG ERROR: $e');                                                     //Something went wrong. Please try again.
} finally {
if (mounted) setState(() => _isLoading = false);
}}
















# ---------- Dependencies ----------

def get_db():
db = SessionLocal()
try:
yield db
finally:
db.close()

def get_current_user(
creds: HTTPAuthorizationCredentials = Depends(bearer_scheme),
db: Session = Depends(get_db),
) -> User:
user_id = decode_token(creds.credentials)
user = db.query(User).filter(User.id == user_id).first()
if not user:
raise HTTPException(status_code=401, detail="User no longer exists")
return user





@app.post("/signup")
def signup(data: SignupRequest, db: Session = Depends(get_db)):
email = data.email.strip().lower()
username = data.username.strip().lower()

if not EMAIL_RE.match(email):
raise HTTPException(status_code=400, detail="Enter a valid email address")
if not USERNAME_RE.match(username):
raise HTTPException(
status_code=400,
detail="Username must be 3-20 characters: lowercase letters, numbers or underscore",
)
check_password_rules(data.password)

if db.query(User).filter(User.email == email).first():
raise HTTPException(status_code=400, detail="Email already registered")
if db.query(User).filter(User.username == username).first():
raise HTTPException(status_code=400, detail="Username already taken")

referred_by = None
code = (data.invitation_code or "").strip().lower()
if code:
referrer = db.query(User).filter(User.username == code).first()
if not referrer:
raise HTTPException(status_code=400, detail="Invalid invitation code")
referred_by = referrer.username

user = User(
email=data.email,
username=data.username,
hashed_password=hash_password(data.password),
full_name=data.full_name,
phone=data.phone,
country=data.country,
reffered_by=data.invitation_code,
)
db.add(user)
try:
db.commit()
except IntegrityError:
db.rollback()
raise HTTPException(status_code=400, detail="Email or username already in use")
db.refresh(user)

token = create_access_token({"sub": str(user.id)})
return {"token": token, "username": user.username, "user_id": user.id}

@app.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
user = db.query(User).filter(User.email == data.email).first()
if not user or not verify_password(data.password, user.hashed_password):
raise HTTPException(status_code=401, detail="Invalid email or password")

token = create_access_token({"sub": str(user.id)})
return {"token": token, "username": user.username, "user_id": user.id}

