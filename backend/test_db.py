from sqlalchemy import text
from app.db import engine

try:
    with engine.connect() as connection:
        result = connection.execute(
            text("SELECT current_database(), current_user")
        )

        database, user = result.fetchone()

        print("Supabase connected successfully!")
        print("Database:", database)
        print("User:", user)

except Exception as error:
    print("Database connection failed!")
    print(error)

finally:
    engine.dispose()