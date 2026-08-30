"""Model-agnostic LLM client for the optimizer.

Reads provider config from configs/llm.yaml and dispatches to the
appropriate SDK. Add new providers by extending _call_<provider>.
"""

import os
from pathlib import Path

import yaml
from dotenv import load_dotenv

load_dotenv()

CONFIG_PATH = Path(__file__).resolve().parent.parent / "configs" / "llm.yaml"


class LLMClient:
    def __init__(self, config_path: str | Path = CONFIG_PATH):
        with open(config_path) as f:
            self.config = yaml.safe_load(f)
        self.provider = self.config["provider"]
        self.model = self.config["model"]
        self.temperature = self.config.get("temperature", 0.4)
        self.max_tokens = self.config.get("max_tokens", 4096)

    def generate(self, prompt: str, system: str | None = None) -> str:
        if self.provider == "anthropic":
            return self._call_anthropic(prompt, system)
        elif self.provider == "openai":
            return self._call_openai(prompt, system)
        elif self.provider == "gemini":
            return self._call_gemini(prompt, system)
        raise ValueError(f"Unknown provider: {self.provider}")

    def _call_anthropic(self, prompt: str, system: str | None) -> str:
        import anthropic

        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            raise RuntimeError("ANTHROPIC_API_KEY not set (check your .env)")

        client = anthropic.Anthropic(api_key=api_key)
        kwargs = {
            "model": self.model,
            "max_tokens": self.max_tokens,
            "temperature": self.temperature,
            "messages": [{"role": "user", "content": prompt}],
        }
        if system:
            kwargs["system"] = system

        response = client.messages.create(**kwargs)
        return "".join(b.text for b in response.content if b.type == "text")

    def _call_openai(self, prompt: str, system: str | None) -> str:
        import openai

        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise RuntimeError("OPENAI_API_KEY not set (check your .env)")

        client = openai.OpenAI(api_key=api_key)
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        response = client.chat.completions.create(
            model=self.model,
            max_tokens=self.max_tokens,
            temperature=self.temperature,
            messages=messages,
        )
        return response.choices[0].message.content

    def _call_gemini(self, prompt: str, system: str | None) -> str:
        from google import genai
        from google.genai import types

        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY not set (check your .env)")

        client = genai.Client(api_key=api_key)
        config = types.GenerateContentConfig(
            temperature=self.temperature,
            max_output_tokens=self.max_tokens,
            system_instruction=system if system else None,
            thinking_config=types.ThinkingConfig(include_thoughts=False),
        )
        response = client.models.generate_content(
            model=self.model,
            contents=prompt,
            config=config,
        )
        # Explicitly skip any "thinking" parts -- don't trust response.text alone,
        # since thinking content can leak into it on some model/SDK versions.
        answer_parts = []
        for part in response.candidates[0].content.parts:
            if getattr(part, "thought", False):
                continue
            if part.text:
                answer_parts.append(part.text)
        return "".join(answer_parts)
