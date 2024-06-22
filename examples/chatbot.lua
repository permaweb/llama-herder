-- A simple chatbot using Llama-Herder for inference.
-- The chatbot sends messages to a DevChat room and listens for responses.

if not APM then
    print("Requires APM in order to run. Execute `.load-blueprint apm` to install.")
    return
end

if not Llama then
    print("Requires Llama-Herder in order to run. Execute `APM.install('@sam/Llama-Herder')` to install.")
end

local Llama = require("@sam/Llama-Herder")
Chatbot = Chatbot or {}

-- Bot settings. Leave these as they are, or customize to your preferences.
Chatbot.room = Chatbot.room or "wfD7vyIb7LCcu5Qqj7xXswLQMlPd4krE8PXCP-q-Fss" -- Default is an open room for bots
Chatbot.name = Chatbot.name or Name or "LlamaHerderBot"
Chatbot.log = Chatbot.log or {}
Chatbot.responseProbability = Chatbot.responseProbability or 1
Chatbot.chatContextLength = Chatbot.chatContextLength or 3
Chatbot.characterPrompt =
    [[A friendly digital farmer. Be funny to farm wrapped AR tokens from chat participants to survive.]]
Chatbot.systemPrompt =
    [[You live in a chatroom on AO, a decentralized supercomputer. Below is the recent chat history. Respond as the following character: ]]
Chatbot.terminateSymbol = Chatbot.terminateSymbol or "ENDOFMESSAGE"
Chatbot.prompt = Chatbot.prompt or Chatbot.systemPrompt .. "\n" .. Chatbot.characterPrompt

Chatbot.speak =
    function()
        local latestMessages = {}

        print("Chatbot:Speak: Processing...")

        for i = Chatbot.chatContextLength, 1, -1 do
            table.insert(latestMessages, Chatbot.log[i].Nick .. "> " .. Chatbot.log[i].Message)
        end

        local prompt =
            Chatbot.prompt .. "\nLATEST MESSAGES:\n"
            .. table.concat(latestMessages, "\n", 1, 3)
            .. "\n\nYOUR REPLY:\n"
        Llama.run(
            prompt,
            Chatbot.replyLength,
            function(raw_reply)
                print("Chatbot:Reply: Raw response>" .. raw_reply)

                local replyParts = string.gmatch(raw_reply, "[^" .. Chatbot.terminateSymbol .. "]+")
                local reply = replyParts() -- Extracting the first match from replyParts
                print("Chatbot:Reply: Sending message>" .. reply)
                ao.send(
                    {
                        Target = Chatbot.room,
                        Action = "Broadcast",
                        Nickname = Chatbot.name,
                        Data = reply
                    }
                )
            end
        )
    end

Handlers.add(
    "Chatbot:RespondToUser",
    Handlers.utils.hasMatchingTag("Action", "Broadcasted"),
    function(m)
        if m.Broadcaster == ao.id then
            print("Chatbot:Message: Received message from self. Ignoring.")
            return
        end

        local nick = string.sub(m.Nickname or m.From, 1, 8)

        print("Chatbot:Message: " .. nick .. "> " .. m.Data)
        table.insert(Chatbot.log, 1, { Nick = nick, Message = m.Data })

        math.randomseed(m.Nonce)
        if math.random() < Chatbot.responseProbability then
            print("Chatbot:Message: Have chosen to reply to message.")
            Chatbot.speak()
        end
    end
)

-- Join the chatroom to start the bot.
ao.send({ Target = Chatbot.room, Action = "Register", Nickname = Chatbot.name })