local bint = require('.bint')(256)
local json = require('json')

WorldID = 'QIFgbqEmk5MyJy01wuINfcRP_erGNNbhqHRkAQjxKgg'
RouterID = 'wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw'
BazarID = 'U3TjJAZWJjlWBB4KAXSHKzuky81jtyh0zqH8rUL4Wd0'
Fee = 100

TradeToken = 'MkZP5EYbDuVS_FfALYGEZIR_hBGnjcWYWqyWN9v096k'
WrappedAR = "xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"

Outcomes = {
    Buy = 0,
    Skip = 0,
    Error = 0,
    Requests = 0
}

Handlers.add(
    'Cron',
    Handlers.utils.hasMatchingTag('Action', 'Cron'),
    function(msg)
        ao.send({ Target = WorldID, Action = 'ChatHistory', Limit = "3" })
    end
)

Handlers.add(
    'ChatHistoryResponse',
    Handlers.utils.hasMatchingTag('Action', 'ChatHistoryResponse'),
    function(msg)
        local prompt = "Grade sentiment 1 to 5: "

        local messages = json.decode(msg.Data)
        for i = 1, 3 do
            prompt = prompt .. "\nMessage> " .. messages[i].Content
        end

        prompt = prompt .. "\n\nGRADE: "

        print(prompt)

        Outcomes.Requests = Outcomes.Requests + 1

        ao.send({
            Target = WrappedAR,
            Recipient = RouterID,
            Action = 'Transfer',
            Quantity = tostring(Fee),
            ["X-Prompt"] = prompt,
            ["X-Tokens"] = tostring(10)
        })
    end
)

Handlers.add(
    'Inference-Response', 
    Handlers.utils.hasMatchingTag('Action', 'Inference-Response'),
    function(msg)
        
        local match = string.match(msg.Data, "(%d+)")
        if not match then
          print("Response does not contain a sentiment grade. Response: " .. msg.Data)
          Outcomes.Error = Outcomes.Error + 1
          return
        end

        print("Sentiment analysed. Grade: " .. match)

        if tonumber(match) > 3 then
            print("Sentiment is positive. Buying...")
        else
            print("Sentiment is negative. Skipping...")
            Outcomes.Skip = Outcomes.Skip + 1
            return
        end

        ao.send({
            Target = WrappedAR,
            Action = 'Transfer',
            Recipient = BazarID,
            Quantity = "100000",
            ['X-Order-Action'] = 'Create-Order',
            ['X-Swap-Token'] = TradeToken,
            ['X-Quantity'] = "100000"
        })
    end
)

Handlers.add(
    "Action-Response",
    Handlers.utils.hasMatchingTag('Action', 'Action-Response'),
    function(msg)
        print("Trade status: " .. msg.Status)
        Outcomes.Buy = Outcomes.Buy + 1
    end
)