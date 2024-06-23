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

Colors = {
    red = "\27[31m",
    green = "\27[32m",
    blue = "\27[34m",
    reset = "\27[0m",
    gray = "\27[90m"
}

function CountWords(prompt)
    local count = 0
    for _ in string.gmatch(prompt, "%w+") do
        count = count + 1
    end
    return count
end

-- Note: The herder counts words, not directs as counted by the LLM.
function CalculateFee(prompt, tokens)
    return SetPromptFee + ((CountWords(prompt) + tokens) * FeePerToken)
end

function DispatchWork()
    for i in pairs(Herd) do
        if #Queue == 0 then
            return
        end

        local work = table.remove(Queue, 1)
        print("[" .. Colors.gray .. "DISPATCHING WORK" .. Colors.reset .. " ]" ..
            " Requested: " .. Colors.blue .. work.reqLength .. Colors.reset ..
            " | Fee: " .. Colors.red .. string.sub(tostring(work.multiplier), 1, 4) .. "x" .. Colors.reset ..
            " | In queue: " .. Colors.blue .. #Queue .. Colors.reset ..
            " | Client: " .. Colors.blue .. string.sub(work.client, 1, 6) .. Colors.reset ..
            " | Worker: " .. Colors.green .. string.sub(Herd[i], 1, 6) .. Colors.reset
        )

        ao.send({
            Target = Herd[i],
            Action = "Inference",
            Tokens = work.tokens,
            Data = work.prompt,
            Termination = work.termination
        })

        LastMultiplier = work.multiplier

        Busy[Herd[i]] = {
            timestamp = work.timestamp,
            client = work.client,
            userReference = work.userReference,
            tokens = work.tokens,
            reqLength = work.reqLength
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

        local reqLength = tonumber(msg["X-Tokens"]) + CountWords(msg["X-Prompt"])

        table.insert(Queue, position, {
            timestamp = msg.Timestamp,
            client = msg.Sender,
            prompt = msg["X-Prompt"],
            tokens = msg["X-Tokens"],
            multiplier = multiplier,
            transferID = msg.Id,
            userReference = msg["X-Reference"],
            termination = msg["X-Termination"],
            reqLength = reqLength
        })

        print("[" .. Colors.gray .. tostring(msg.Timestamp) .. Colors.reset .. ":" .. Colors.blue .. "REQ" .. Colors.reset .. "]" ..
            " Requested: " .. Colors.blue .. reqLength .. Colors.reset ..
            " | Fee: " .. Colors.red .. string.sub(tostring(multiplier), 1, 4) .. "x" .. Colors.reset ..
            " | In queue: " .. Colors.blue .. #Queue .. Colors.reset ..
            " | Client: " .. Colors.blue .. string.sub(msg.Sender, 1, 6) .. Colors.reset ..
            " | Client ref: " .. Colors.gray .. string.sub(msg["X-Reference"], 1, 10) .. Colors.reset
        )

        DispatchWork()
    end
)

Handlers.add(
    "InferenceResponseHandler",
    Handlers.utils.hasMatchingTag("Action", "Inference-Response"),
    function(msg)
        if not Busy[msg.From] then
            print("[" .. Colors.gray .. tostring(msg.Timestamp) .. Colors.reset .. ":" .. Colors.red .. "ERR" .. Colors.reset .. "]" ..
                " Inference-Response not from worker." ..
                " | Worker: " .. Colors.blue .. string.sub(msg.From, 1, 6) .. Colors.reset
            )
            return
        end
        
        print("[" .. Colors.gray .. tostring(msg.Timestamp) .. Colors.reset .. ":" .. Colors.green .. "RES" .. Colors.reset .. "]" ..
            " Requested: " .. Colors.green .. Busy[msg.From].reqLength .. Colors.reset ..
            " | Duration: " .. Colors.blue .. string.sub(tostring((msg.Timestamp - Busy[msg.From].timestamp) / 1000), 1, 4) .. Colors.reset .. "s" ..
            " (" .. Colors.red .. string.sub(tostring(Busy[msg.From].reqLength / ((msg.Timestamp - Busy[msg.From].timestamp) / 1000)), 1, 4) .. Colors.reset .. " tks/s)" ..
            " | Client: " .. Colors.blue .. string.sub(Busy[msg.From].client, 1, 6) .. Colors.reset ..
            " | Worker: " .. Colors.green .. string.sub(msg.From, 1, 6) .. Colors.reset ..
            " | Client ref: " .. Colors.gray .. string.sub(Busy[msg.From].userReference, 1, 10) .. Colors.reset
        )

        ao.send({
            Target = Busy[msg.From].client,
            Action = "Inference-Response",
            ["X-Reference"] = Busy[msg.From].userReference,
            Data = msg.Data
            -- Duration = msg.Timestamp - Busy[msg.From].timestamp
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
        print("[" .. Colors.gray .. tostring(msg.Timestamp) .. Colors.reset .. ":" .. Colors.blue .. "INFO" .. Colors.reset .. "]" ..
            " Client: " .. Colors.blue .. string.sub(msg.From, 1, 6) .. Colors.reset
        )
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