local bint = require('.bint')(256)
local json = require('json')

WORLD_PROCESS = 'TODO'
ROUTER_PROCESS = 'TODO'
UCM_PROCESS = 'U3TjJAZWJjlWBB4KAXSHKzuky81jtyh0zqH8rUL4Wd0'

TRADE_TOKEN = 'TODO'
SWAP_TOKEN = 'xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10'

Handlers.add('Cron', Handlers.utils.hastMatchingTag('Action', 'Cron'), function(msg)
    ao.send({ Target = WORLD_PROCESS, Action = 'ChatHistory' })
end)

Handlers.add('ChatHistoryResponse', Handlers.utils.hastMatchingTag('Action', 'ChatHistoryResponse'), function(msg)
    local promptData = {}

    for _, message in ipairs(json.decode(msg.Data)) do
        table.insert(promptData, message.Content)
    end

    ao.send({
        Target = ROUTER_PROCESS,
        Action = 'HandlePrompt',
        Data = json.encode(promptData)
    })
end)

Handlers.add('PromptResponse', Handlers.utils.hasMatchingTag('Action', 'PromptResponse'), function(msg)
    local signal = msg.Tags.Signal
    local quantity = tostring(bint(100) * bint(100000000))

    if signal then
        ao.send({
            Target = TRADE_TOKEN,
            Action = 'Transfer',
            Tags = {
                Recipient = UCM_PROCESS,
                Quantity = quantity,
                ['X-Order-Action'] = 'Create-Order',
                ['X-Swap-Token'] = SWAP_TOKEN,
                ['X-Quantity'] = quantity
            }
        })
    end
end)

