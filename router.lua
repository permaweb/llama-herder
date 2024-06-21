WrappedAR = "xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"

Herd = {
    -- List of open worker processes
	"t0BJd_XiGj_ImJeNgBjmjooq3h_YSA6AxKf2rA1owIk",
	"q619HbaDOu2IAAHHZ3hMBeFJDcVAkRcnNrAVrMVJ03U"
	"-2mxT-kgqxMUoSimS2xcCuQGNs9yhbryILBfanhcopA",
	"r3s3XxBwGlom12zeuG8FznR4YBiwUDqXnHXdzkJAw_8",
	"qYLdQ43zk0YYEsFO1YNNjTIDQsjpXiCMCujWw19DVuY",
	"UDGS0ZmqAGnHlSGOfMkClJvqVtS1oR6mG1c36JnDBso",
	"VDsyx6skRIxG7BlLKRMLZ5r6poWWXEj47gfbnsKFCpI",
	"mCb0wzMu5bM9OKMBhPKr0MnprP51fmimy9YJYyvm4bg",
	"WP7uFPpQ6W-sZBJWcgRppPO9Ff-f5vw8tVK4qE93i60",
	"p6fai5xVaqFEs-kfzhUjXKnQ1pxb8MnRWdHFwiJlQgw",
	"cxaC2AF-C4rfRzMuKnzoUup6FzL0uT-BNnM4dIt6sy8"
	"6H4-NYfjonYtsese6CRo1oGS95H2xv5PBaxF-qYMVMs",
	"biDg2KxioPA3qCdX4kXo1FcIgbreWj6sZ_kIZZXkoUI",
	"g3k7frEMLlIw69bFqZEEf3AxcTXbe0SIW8ruhD7hBe0",
	"3DoLwimFJUG3p_y2twB2BScEbhbBsFIK86nL1sT0iJQ",
	"3txeC7qcVRuVJ-l34B8QprXSwrU08-kzsPCSm2u3Ajo"
    "rAOuOXvQRNZcGOtT_GLoGAONC9W_6YsAQLpvr3twdvs",
    "B4VlH3zAvxV8phFmNinVG8NLXON1msarsKwa0osmGfU",
    "crN7jwF6pRTxGxkcfsSlubSISzTyJ8zCAFWKyLHRJVI"
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

