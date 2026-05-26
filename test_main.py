import sys
sys.path.append('.')
try:
    import src.main
    print("Successfully imported src.main")
except Exception as e:
    import traceback
    traceback.print_exc()
