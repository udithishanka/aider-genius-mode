import openai
import os

def call_openai_api(prompt):
    openai.api_key = os.getenv("OPENAI_API_KEY")
    
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    
    return response.choices[0].message['content']

def get_sentiment(message):
    openai.api_key = os.getenv("OPENAI_API_KEY")
    
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": f"Analyze the sentiment of the following message: '{message}'"}
        ]
    )
    
    return response.choices[0].message['content']

if __name__ == "__main__":
    user_prompt = input("Enter your prompt for OpenAI: ")
    response = call_openai_api(user_prompt)
    print("OpenAI Response:", response)
    
    sentiment_response = get_sentiment(user_prompt)
    print("Sentiment Analysis:", sentiment_response)
