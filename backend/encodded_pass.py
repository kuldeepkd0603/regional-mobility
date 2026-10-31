from getpass import getpass
from urllib.parse import quote

password = getpass("Enter your Supabase password: ")

encoded = quote(password, safe="")

print("\nEncoded password:")
print(encoded)