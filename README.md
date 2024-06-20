# Llama as a Service

## Overview

The Llama service is designed to provide the necessary workers and load balancing needed for inferencing inside Large Language Models (LLMs) on AO. This service is composed of two main components: the worker (`llama`) and the router (load balancer or `herder`).

### Worker (Llama)
The worker is responsible for handling inference requests. It loads the model, processes user prompts, and generates responses.

#### Initialization
- **ModelID:** `"ISrbGzQot05rs_HKC08O_SmkipYQnqB1yC3mjZZeEo"`
- **RouterID:** `"wh5vB2IbqmIBUqgodOaTvByNFDPr73gbUq1bVOUtCrw"`
- **Llama:** Llama instance or `nil`

#### Key Functions
- **Init()**: Initializes the Llama instance by loading the model.
- **ProcessRequest(userPrompt, tokenCount)**: Processes the user prompt and generates a response based on the token count.
- **GeneratePrompt(userPrompt)**: Formats the user prompt for processing.

#### Handlers
- **Init**: Initializes the worker with the provided model ID.
- **Inference**: Handles inference requests, ensuring they come from the router and processing them accordingly.

### Router (Load Balancer or 'Herder')
The router manages the distribution of inference tasks to available workers, handles payment calculations, and maintains a queue for pending requests.

#### Key Variables
- **WrappedAR**: `"xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"`
- **Herd**: List of worker processes.
- **Busy**: Tracks busy workers.
- **Queue**: Maintains pending requests.
- **SetPromptFee**: Fee for setting the prompt.
- **FeePerToken**: Fee per token generated.

#### Key Functions
- **CalculateFee(prompt, tokens)**: Calculates the total fee based on the prompt and token count.
- **DispatchWork()**: Dispatches work to available workers from the queue.

#### Handlers
- **Start-Inference**: Handles start-inference requests, validates payment, and queues the work.
- **InferenceResponseHandler**: Handles responses from workers, sends the response back to the client, and updates the worker status.

### Agent (Client Example)
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

## Usage

1. **Initialize the Worker**:
   - Send a message with the action "Init" to initialize the worker with the model ID.

2. **Send Inference Requests**:
   - The router receives requests and calculates the necessary fee.
   - Valid requests are queued and dispatched to available workers.
   - Workers process the requests and send back responses.

3. **Handle Responses**:
   - The router receives responses from workers, forwards them to the original requesters, and updates the status of the workers.

4. **Example Client**:
   - An example client periodically requests chat history, analyzes sentiment, and performs trading actions based on the analysis.