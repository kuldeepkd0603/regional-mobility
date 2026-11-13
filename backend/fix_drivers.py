
with open(r'C:\regional-mobility\backend\app\api\routes\drivers.py', 'r', encoding='utf-8') as f:
    content = f.read()

# The marker to insert before (the get_driver route comment)
marker = '\n\n# Driver can view own profile; admin can view any profile\n@router.get("/{driver_id}", response_model=DriverResponse)'

new_endpoint = '''

# Driver can view their own driver profile
@router.get("/me", response_model=DriverResponse)
def get_my_driver_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.DRIVER))
):
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver profile not found"
        )
    return driver'''

replacement = new_endpoint + '\n\n\n# Driver can view own profile; admin can view any profile\n@router.get("/{driver_id}", response_model=DriverResponse)'

if marker in content:
    new_content = content.replace(marker, replacement, 1)
    with open(r'C:\regional-mobility\backend\app\api\routes\drivers.py', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("SUCCESS: /me endpoint inserted")
else:
    # Try to debug
    idx = content.find('# Driver can view own profile')
    print(f"Marker not found. 'Driver can view own profile' at index: {idx}")
    if idx >= 0:
        snippet = content[max(0, idx-10):idx+80]
        print(repr(snippet))
