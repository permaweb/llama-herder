ModelID = "ISrbGzQot05rs_HKC08O_SmkipYQnqgB1yC3mjZZeEo"
RouterID = "wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw"
Llama = Llama or nil

function Init()
  Llama = require("llama")
  Llama.logLevel = 4
  Llama.load("/data/" .. ModelID)
end

function ProcessRequest(userPrompt, tokenCount)
  Llama.setPrompt(userPrompt)
  local response = ""
  for i = 1, tokenCount do
    response = response .. Llama.next()
  end
  return response
end

function GeneratePrompt(userPrompt)
  return "<|USER|>" .. userPrompt .. "<|ASSISTANT|>"
end

Handlers.add(
  "Init",
  Handlers.utils.hasMatchingTag("Action", "Init"),
  function(msg)
    ModelID = msg.Tags["Model-ID"] or ModelID
    Init()
    Send({ Target = msg.From, Action = "Worker-Initialized" })
  end
)

Handlers.add(
  "Inference",
  Handlers.utils.hasMatchingTag("Action", "Inference"),
  function(msg)
    print("Performing inference. Prompt: " .. msg.Data)

    if msg.From ~= RouterID then
      print("Inference request from non-router. From: " .. msg.From)
      return
    end

    local response = ProcessRequest(msg.Data, tonumber(msg.Tokens))
    print("Response:" .. response)

    ao.send({
      Target = msg.From,
      Action = "Inference-Response",
      Data = response
    })
  end
)
