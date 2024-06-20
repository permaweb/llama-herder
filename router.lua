WrappedAR = "xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"

Herd = {
    -- List of open worker processes
    "B0YVJ83M9KstjfZeCNoK0m7MnhzEVlSMz-GDcq5gPQw",
    "YVjnwtjnY1vSXMiJobLNgkr5Ft_LTECFXD5BufDNAaA",
    "J7zej-2rL0oJ8cvNR-RNzMicLgXUIRwLMxMvf1T9Q2E"
}
Busy = {}
Queue = {}

SetPromptFee = 1
FeePerToken = 1

function CalculateFee(prompt, tokens)
    local tokenCount = tokens
    for _ in string.gmatch(prompt, "%w+") do
       tokenCount = tokenCount + 1
    end

    return SetPromptFee + (tokenCount * FeePerToken)
end

function DispatchWork()
    for i in pairs(Herd) do
        if #Queue == 0 then
            return
        end

        local work = table.remove(Queue, 1)
        print("Dispatching work. Worker: " .. Herd[i] .. "\nPrompt: " .. work.prompt)
        ao.send({
            Target = Herd[i],
            Action = "Inference",
            Tokens = work.tokens,
            Data = work.prompt,
        })

        Busy[Herd[i]] = work.client
        table.remove(Herd, i)
    end
end

Handlers.add(
    "Start-Inference",
    function(msg)
        return msg.Action == "Credit-Notice" and
            msg.From == WrappedAR
    end,
    function(msg)
        print("Inference request. Prompt: " .. msg["X-Prompt"])
        local needed = CalculateFee(msg["X-Prompt"], tonumber(msg["X-Tokens"]))
        if needed > tonumber(msg.Quantity) then
            print("Start-Inference. Insufficient payment: " .. msg.Quantity)
            ao.send({
                Target = WrappedAR,
                Recipient = msg.From,
                Action = "Transfer",
                Quantity = msg.Quantity,
                ["X-Reason"] = "Insufficient payment",
                ["X-Needed"] = tostring(needed)
            })
            return
        end

        table.insert(Queue, {
            client = msg.Sender,
            prompt = msg["X-Prompt"],
            tokens = msg["X-Tokens"],
            transferID = msg.Id
        })

        print("Inference request. Queue: " .. #Queue)

        DispatchWork()
    end
)

Handlers.add(
    "InferenceResponseHandler",
    Handlers.utils.hasMatchingTag("Action", "Inference-Response"),
    function(msg)
        print("Inference-Response. From: " .. msg.From .. "\nData: " .. msg.Data)
        print("Busy: " .. Busy[msg.From])
        if not Busy[msg.From] then
            print("Inference-Response not from worker.")
            return
        end

        ao.send({
            Target = Busy[msg.From],
            Action = "Inference-Response",
            Data = msg.Data,
        })

        Busy[msg.From] = nil
        table.insert(Herd, msg.From)

        DispatchWork()
    end
)

