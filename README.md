# Llama-Herder: Llamas as a decentralized Service
---
![Llama-Herder](https://ro2jxrzi2hqt3fk6o2zprjjrw75c7r7z6a4xopcwcu74nh23hdlq.arweave.net/i7SbxyjR4T2VXnay-KUxt_ovx_nwOXc8VhU_xp9bONc)

The 'Llama as a Service' infrastructure is designed to provide AO users with a fully decentralized LLM inference environment that is easy to use. Send one simple AO message to the Llama herder and you will receive a response from one of the herded inference workers.

In the background, `Llama-Herder` offers the services of [AOS-Llama](https://github.com/samcamwilliams/aos-llama), a port of [Llama.cpp](https://github.com/ggerganov/llama.cpp). AOS-Llama allows users to execute Meta's Llama models, Microsoft's Phi models, amongst many others in AO's fully onchain environment.

`Llama-Herder` works by 'herding' a set of worker processes that are running AOS-Llama inference. The herder process manages the queue of requests and dispatches them to the available workers when they are available. Each worker runs fully asynchronously and in parallel.

## Getting Started

Interacting with `Llama-Herder` is simple. There is a public `Llama-Herder` that is open for all to use, paying for the service using [Wrapped AR](https://aox.xyz/#/beta). This service presently runs Microsoft's Phi-3 Instruct model, as it is faster and efficent for most tasks. More public Llama Herders offering different models will be added over time.

There are two ways to interact with a herder:

### Using the AOS Library

First, make sure you have [APM](https://apm_betteridea.g8way.io/) installed. You can do so by running the following command on the AOS terminal:

```bash
.load-blueprint apm
```

Then, simply install the `Llama-Herder` package:

```lua
APM.install("@sam/Llama-Herder")
```

Run inference by calling the module:

**Important:** _Remember that you will need to have [Wrapped AR](https://aox.xyz/#/beta) held by your process before you can run prompts!_

```lua
Llama = require("@sam/Llama-Herder")

-- Run a simple prompt that prints to the console:
Llama.run("Write a story in 10 words or less.", 10)
-- You will see your response on your terminal after 30 seconds to a few minutes (depending on your prompt length).

-- Full inference arguments:
Llama.run(
   "What is the meaning of life?", -- Your prompt
   20, -- Number of tokens to generate
   function(generated_text, response_message) -- Optional: A function to handle the response
      -- Do something with your LLM inference response
   end,
   {
      Fee = 100, -- Optional: The total fee in Winston you would like to pay; OR
      Multiplier = 1.1 -- Optional: If not using an automatic or static fee,
      -- you can set the multiplier on the last accepted fee that you would like to pay
   },
   "myCustomReference" -- Optional: A custom reference for your request (will show up in the response_message's 'X-Reference' field)
)
```

Setting the multiplier allows you to prioritize your request over other users. The multiplier is a number that you can set to 1.05, 1.1, 1.2, etc. The higher the multiplier, the higher the priority of your request. AO can support any number of parallel processes, but [Forward Research](https://fwd.g8way.io) is currently subsidizing compute. Subsequently, the open access `Llama-Herder` currently uses a set of ~20 parallel workers. This can be increased in the future as needed.

### Sending Messages

You can use the `Llama-Herder` directly by simply sending a message to it (via Wrapped AR) and it will return a response.

```lua
ao.send({
   Target = 'xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10',
   Action = 'Transfer',
   Recipient = 'wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw',
   Quantity = Fee,
   ['X-Prompt'] = 'What is the meaning of life?',
   ['X-Tokens'] = '10'
})
```

In order to calculate appropriate fees for your request, you can use the following formula:

```lua
Fee = (FeePerToken * Tokens) + SetPromptFee
```

You can get the current fees by sending a message with an `Action: Info` tag to the herder process. It will respond with a message containing the current rates.

```lua
ao.send({
   Target = 'wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw',
   Action = 'Info'
})
```

## Examples

The [examples](https://github.com/samcamwilliams/Llama-Herder/tree/main/examples) folder contains a few examples of how to use the `Llama-Herder` in practice.

[`sentiment-agent.lua`](https://github.com/samcamwilliams/Llama-Herder/blob/main/examples/sentiment-agent.lua) is a simple example of a client that interacts with the `Llama-Herder` to analyze sentiment from chat history and make trading decisions based on the sentiment. This example uses 'raw' messages to interact with the open access `Llama-Herder`.

[`chatbot.lua`](https://github.com/samcamwilliams/Llama-Herder/blob/main/examples/chatbot.lua) is a simple example of a client that uses the `Llama-Herder` module to send prompts and receive responses from the `Llama-Herder`. It writes its messages to a [DevChat](https://github.com/samcamwilliams/DevChat) room which anyone can join.

Load the examples by cloning this repo. Run them using `.load` in the AOS CLI:

```lua
.load examples/chatbot.lua
```

Remember that your process will need Wrapped AR tokens before the bot will function!

## Running A Llama Herd

In general, most users will be well-served by using the public Llama herd as described above. In this section we describe how to run a Llama herd if you have requirements that make it necessary.

### Core Features

- Worker initialization and inference processing
- Load balancing and request handling
- Fee calculation and request queuing
- Client example for sentiment analysis and trading decisions

### Prerequisites

- [Node.js](https://nodejs.org/en) (v20.0 or later)
- [AOS installed](https://cookbook_ao.arweave.dev/welcome/getting-started.html)

### Architecture

#### Worker (Llama)

The worker is responsible for handling inference requests. It loads the model, processes user prompts, and generates responses.

##### Initialization
- **ModelID:** `"ISrbGzQot05rs_HKC08O_SmkipYQnqB1yC3mjZZeEo"`
- **RouterID:** `"wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw"`
- **Llama:** Llama instance or `nil`

##### Key Functions
- **Init()**: Initializes the Llama instance by loading the model.
- **ProcessRequest(userPrompt, tokenCount)**: Processes the user prompt and generates a response based on the token count.

##### Handlers
- **Init**: Initializes the worker with the provided model ID.
- **Inference**: Handles inference requests, ensuring they come from the router and processing them accordingly.

#### Router (Load Balancer or 'Herder')

The router manages the distribution of inference tasks to available workers, handles payment calculations, and maintains a queue for pending requests.

##### Key Variables
- **WrappedAR**: `"xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"`
- **Herd**: List of worker processes.
- **Busy**: Tracks busy workers.
- **Queue**: Maintains pending requests.
- **SetPromptFee**: Fee for setting the prompt.
- **FeePerToken**: Fee per token generated.

##### Key Functions
- **CalculateFee(prompt, tokens)**: Calculates the total fee based on the prompt and token count.
- **DispatchWork()**: Dispatches work to available workers from the queue.

##### Handlers
- **Start-Inference**: Handles start-inference requests, validates payment, and queues the work.
- **InferenceResponseHandler**: Handles responses from workers, sends the response back to the client, and updates the worker status.

#### Agent (Client Example)

An example client that interacts with the Llama service to analyze sentiment from chat history and make trading decisions based on the sentiment.

#### Key Variables
- **WorldID**: `'QIFgbqEmk5MyJy01wuINfcRP_erGNNbhqHRkAQjxKgg'`
- **RouterID**: `'wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw'`
- **BazarID**: `'U3TjJAZWJjlWBB4KAXSHKzuky81jtyh0zqH8rUL4Wd0'`
- **Fee**: `100`
- **TradeToken**: `'MkZP5EYbDuVS_FfALYGEZIR_hBGnjcWYWqyWN9v096k'`
- **WrappedAR**: `"xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"`
- **Outcomes**: Tracks outcomes of sentiment analysis.

#### Handlers
- **Cron**: Requests chat history at regular intervals.
- **ChatHistoryResponse**: Processes chat history and sends inference requests.
- **Inference-Response**: Handles inference responses and makes trading decisions based on sentiment analysis.
- **Action-Response**: Handles trade status responses.

### Booting Up the Herd

1. **Initialize the Worker**:
   - Open the aos command-line interface (CLI) by typing `aos` in your terminal and pressing Enter.
   - Send a message with the action "Init" to initialize the worker with the model ID:
     ```lua
     Send({ Target = "worker_process_id", Action = "Init", ModelID = "ISrbGzQot05rs_HKC08O_SmkipYQnqB1yC3mjZZeEo" })
     ```
   - Replace `"worker_process_id"` with the actual process ID of the worker.

2. **Send Inference Requests**:
   - The router receives requests and calculates the necessary fee.
   - Valid requests are queued and dispatched to available workers.
   - Workers process the requests and send back responses.

3. **Handle Responses**:
   - The router receives responses from workers, forwards them to the original requesters, and updates the status of the workers.

## Contributing

We welcome contributions! If you find a bug or have suggestions, please open an issue. If you'd like to contribute code, please fork the repository and submit a pull request.

🦙🦙🦙🦙🦙
