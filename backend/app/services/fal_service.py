import os
import fal_client
from typing import Optional
import base64
from io import BytesIO
from PIL import Image
import httpx


class FalService:
    def __init__(self):
        self.api_key = os.getenv("FAL_API_KEY")
        if not self.api_key:
            raise ValueError("FAL_API_KEY must be set in environment variables")

        # Set the API key for fal_client
        os.environ["FAL_KEY"] = self.api_key

    async def upload_image_to_fal(self, image_data: bytes) -> str:
        """
        Upload image to fal.ai storage and return the URL
        """
        try:
            # Upload the image using fal_client
            url = fal_client.upload(image_data, "image/png")
            return url
        except Exception as e:
            raise Exception(f"Failed to upload image to fal.ai: {str(e)}")

    async def edit_image(
        self,
        image_url: str,
        prompt: str,
        model: str = "fal-ai/bytedance/seedream/v4/edit"
    ) -> dict:
        """
        Send image editing request to fal.ai
        Using ByteDance Seedream v4 Edit model for image editing
        """
        try:
            # Prepare the arguments for the Seedream v4 model
            arguments = {
                "prompt": prompt,
                "image_urls": [image_url],  # Seedream v4 uses image_urls (array)
                "num_images": 1,
                "max_images": 1,
                "enable_safety_checker": True,
                "enhance_prompt_mode": "standard",
                "image_size": {
                    "width": 2048,
                    "height": 2048
                }
            }

            # Subscribe to the model and get results
            handler = fal_client.submit(
                model,
                arguments=arguments
            )

            # Wait for the result
            result = handler.get()

            # Extract the generated image URL
            if result and "images" in result and len(result["images"]) > 0:
                edited_image_url = result["images"][0]["url"]
                return {
                    "success": True,
                    "edited_image_url": edited_image_url,
                    "result": result
                }
            else:
                return {
                    "success": False,
                    "error": "No image generated"
                }

        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    async def process_image_edit(
        self,
        image_data: bytes,
        prompt: str
    ) -> dict:
        """
        Complete flow: upload image and edit it
        """
        try:
            # Upload the image
            image_url = await self.upload_image_to_fal(image_data)

            # Edit the image
            result = await self.edit_image(image_url, prompt)

            if result["success"]:
                return {
                    "success": True,
                    "original_image_url": image_url,
                    "edited_image_url": result["edited_image_url"]
                }
            else:
                return {
                    "success": False,
                    "error": result["error"],
                    "original_image_url": image_url
                }

        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }


# Singleton instance
fal_service = FalService()
