from llama_cpp import Llama

MODEL_3B_PATH = "./DeepSeek-R1-Distill-Llama-3B-Q4_K_M.gguf"

try:
    model = Llama(
        model_path=MODEL_3B_PATH,
        n_ctx=2048,
        n_batch=512,
        n_gpu_layers=-1,
        verbose=True,
    )
except (FileNotFoundError, OSError, RuntimeError) as e:
    print(f"Error loading model: {e}")

context = [
    {
        "role": "system",
        "content": "Tu es un assistant chatbot qui réponds à mes réflexions sur la vie et m'aide à l'appréhender et la développer mes idées d'autres générales. Tu réponds en français de manière amicale."
    },
    {
        "role": "user",
        "content": "Hello, comment ça va ?"
    }
]

message = model.create_chat_completion(messages=context)
print(message["choices"][0]["message"].get("content"))
