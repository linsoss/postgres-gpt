create function ai_text_completion(prompt varchar, max_token integer = 256)
    returns varchar
as
$$
    import openai

    rsp = openai.Completion.create(
        model="text-davinci-003",
        prompt=prompt,
        temperature=0.7,
        max_tokens=max_token
    )
    return rsp['choices'][0]['text']

$$ language plpython3u;