WrappedAR = "xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"

Herd = Herd or {
    -- List of open worker processes
	"q619HbaDOu2IAAHHZ3hMBeFJDcVAkRcnNrAVrMVJ03U",
	"-2mxT-kgqxMUoSimS2xcCuQGNs9yhbryILBfanhcopA",
	"r3s3XxBwGlom12zeuG8FznR4YBiwUDqXnHXdzkJAw_8",
	"qYLdQ43zk0YYEsFO1YNNjTIDQsjpXiCMCujWw19DVuY",
	"UDGS0ZmqAGnHlSGOfMkClJvqVtS1oR6mG1c36JnDBso",
	"mCb0wzMu5bM9OKMBhPKr0MnprP51fmimy9YJYyvm4bg",
	"WP7uFPpQ6W-sZBJWcgRppPO9Ff-f5vw8tVK4qE93i60",
	"p6fai5xVaqFEs-kfzhUjXKnQ1pxb8MnRWdHFwiJlQgw",
	"cxaC2AF-C4rfRzMuKnzoUup6FzL0uT-BNnM4dIt6sy8",
	"6H4-NYfjonYtsese6CRo1oGS95H2xv5PBaxF-qYMVMs",
	"biDg2KxioPA3qCdX4kXo1FcIgbreWj6sZ_kIZZXkoUI",
	"3DoLwimFJUG3p_y2twB2BScEbhbBsFIK86nL1sT0iJQ",
	"3txeC7qcVRuVJ-l34B8QprXSwrU08-kzsPCSm2u3Ajo",
	"rAOuOXvQRNZcGOtT_GLoGAONC9W_6YsAQLpvr3twdvs",
	"B4VlH3zAvxV8phFmNinVG8NLXON1msarsKwa0osmGfU",
    "crN7jwF6pRTxGxkcfsSlubSISzTyJ8zCAFWKyLHRJVI"
}
Busy = Busy or {}
Queue = Queue or {}

SetPromptFee = SetPromptFee or 1
FeePerToken = FeePerToken or 1

LastMultiplier = LastMultiplier or 1

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
        print("Dispatching work from queue. Priority: " .. work.multiplier .. ". Worker: " .. Herd[i])
        ao.send({
            Target = Herd[i],
            Action = "Inference",
            Tokens = work.tokens,
            Data = work.prompt,
        })

        LastMultiplier = work.multiplier

        Busy[Herd[i]] = {
            client = work.client,
            userReference = work.userReference
        }
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
        local needed = CalculateFee(msg["X-Prompt"], tonumber(msg["X-Tokens"]))
        local multiplier = tonumber(msg.Quantity) / needed

        print("Inference request. Base fee: " .. needed .. " | Multiplier: " .. multiplier)

        if multiplier < 1 then
            print("Insufficient payment: " .. msg.Quantity)
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

        local position = 0
        for i = 1, #Queue do
            if multiplier > Queue[i].multiplier then
                position = i
                break
            end
        end

        if position == 0 then
            position = #Queue + 1
        end

        table.insert(Queue, position, {
            client = msg.Sender,
            prompt = msg["X-Prompt"],
            tokens = msg["X-Tokens"],
            multiplier = multiplier,
            transferID = msg.Id,
            userReference = msg["X-Reference"]
        })

        print("Added to queue. Current size: " .. #Queue)

        DispatchWork()
    end
)

Handlers.add(
    "InferenceResponseHandler",
    Handlers.utils.hasMatchingTag("Action", "Inference-Response"),
    function(msg)
        print("Inference-Response. From: " .. msg.From .. ". Data length: " .. string.len(msg.Data))
        if not Busy[msg.From] then
            print("Inference-Response not from worker.")
            return
        end

        ao.send({
            Target = Busy[msg.From].client,
            Action = "Inference-Response",
            ["X-Reference"] = Busy[msg.From].userReference,
            Data = msg.Data,
        })

        Busy[msg.From] = nil
        table.insert(Herd, msg.From)

        DispatchWork()
    end
)

Handlers.add(
    "Info",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        print("Info request. From: " .. msg.From)
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Name = "Llama-Herder",
            Version = "0.2",
            ["Base-Fee"] = tostring(SetPromptFee),
            ["Token-Fee"] = tostring(FeePerToken),
            ["Last-Multiplier"] = tostring(LastMultiplier),
            ["Queue-Length"] = tostring(#Queue),
            Data = [[A decentralized service for Llama 3 inference.
            This process is a herder of Llama 3 workers. It dispatches work to
            a herd of many worker processes and forwards their responses.
            ]]
        })
    end
)