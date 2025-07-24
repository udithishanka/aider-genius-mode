import openai

# Set your OpenAI API key
openai.api_key = 'YOUR_API_KEY'

def get_sentiment(sentence):
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": f"What is the sentiment of the following sentence: '{sentence}'?"}
        ]
    )
    sentiment = response['choices'][0]['message']['content']
    return sentiment

if __name__ == "__main__":
    sentence = "I love programming!"
    sentiment = get_sentiment(sentence)
    print(f"The sentiment of the sentence is: {sentiment}")
