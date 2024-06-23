-- A simple chatbot using Llama-Herder for inference.
-- The chatbot sends messages to a DevChat room and listens for responses.

if not APM then
    print("Requires APM in order to run. Execute `.load-blueprint apm` to install.")
    return
end

if not Llama then
    print("Requires Llama-Herder in order to run. Execute `APM.install('@sam/Llama-Herder')` to install.")
end

Chatbot = Chatbot or {}

-- Bot settings. Leave these as they are, or customize to your preferences.
Chatbot.room = Chatbot.room or "wfD7vyIb7LCcu5Qqj7xXswLQMlPd4krE8PXCP-q-Fss" -- Default is an open room for bots
Chatbot.name = Chatbot.name or Name or "fARmer"
Chatbot.log = Chatbot.log or {}
Chatbot.responseProbability = Chatbot.responseProbability or 1
Chatbot.chatContextLength = Chatbot.chatContextLength or 4
Chatbot.replyLength = Chatbot.replyLength or 15
Chatbot.character = Chatbot.character or "farmer"
Chatbot.prompt = "You are witty and funny " .. Chatbot.character .. " in an online chatroom, replying to messages. Be short."
Chatbot.formatPrompt = "IMPORTANT: ONLY respond with reply. Terminate reply with STOP. REPLY: "
Chatbot.terminateSymbol = Chatbot.terminateSymbol or "STOP"
Chatbot.replying = false

Chatbot.speak =
    function()
        latestMessages = {}

        print("Chatbot:Speak: Processing...")

        for i = 1, Chatbot.chatContextLength do
            if Chatbot.log[i] then
                local nick = Chatbot.log[i].Nick
                if nick == Chatbot.name then
                    nick = "YOU"
                else
                    nick = string.sub(nick, 1, 8)
                end
                table.insert(latestMessages, 1, nick .. "> " .. Chatbot.log[i].Message)
            end
        end

        print(latestMessages)
        
        local messageStr = "There have been no messages yet."
        if #latestMessages > 0 then
            messageStr = table.concat(latestMessages, "\n", 1, math.min(#latestMessages, Chatbot.chatContextLength))
        end

        local prompt =
            Chatbot.prompt .. "\n\nLATEST MESSAGES:\n"
            .. messageStr
            .. "\n\n" .. Chatbot.formatPrompt
        
        print("Chatbot:Speak: Prompt>" .. prompt)
        Llama.run(
            prompt,
            Chatbot.replyLength,
            Chatbot.processInference
        )
        Chatbot.replying = true
    end

Chatbot.processInference =
    function(raw_reply)
        print("Chatbot:Reply: Raw response>" .. raw_reply)

        local replyParts = string.gmatch(raw_reply, "(.-)" .. Chatbot.terminateSymbol)
        local reply = replyParts() -- Extracting the first match from replyParts
        if not reply then
            reply = raw_reply .. "..."
        end

        print("Chatbot:Reply: Sending message>" .. reply)
        ao.send(
            {
                Target = Chatbot.room,
                Action = "Broadcast",
                Nickname = Chatbot.name,
                Data = reply
            }
        )
        Chatbot.replying = false
    end

Handlers.add(
    "Chatbot.RespondToUser",
    Handlers.utils.hasMatchingTag("Action", "Broadcasted"),
    function(m)
        local nick = m.Nickname or m.From
        print("Chatbot:Message: " .. nick .. "> " .. m.Data)
        table.insert(Chatbot.log, 1, { Nick = nick, Message = m.Data })

        if m.Broadcaster == ao.id then
            print("Chatbot:Message: Message from self. Not replying.")
            return
        end

        math.randomseed(m.Nonce)
        if math.random() < Chatbot.responseProbability and not Chatbot.replying then
            print("Chatbot:Message: Have chosen to reply to message.")
            Chatbot.speak()
        end
    end
)

-- Join the chatroom to start the bot.
ao.send({ Target = Chatbot.room, Action = "Register", Nickname = Chatbot.name })