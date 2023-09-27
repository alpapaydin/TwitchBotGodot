import os
import subprocess
import pygame 
import random
import yt_dlp
import asyncio
import websockets
from twitchio.ext import commands, sounds
from twitchio import User
from gtts import gTTS
from datetime import datetime, timezone, timedelta
from youtubesearchpython import VideosSearch
from moviepy.editor import AudioFileClip  # Import AudioFileClip class
from dotenv import load_dotenv

# Load .env file
load_dotenv()

# Retrieve variables
token = os.getenv("TOKEN")
adminuserid = os.getenv("ADMIN_USER_ID")
channelname = os.getenv("CHANNEL_NAME")
discordlink = os.getenv("DISCORD_LINK")

pygame.mixer.init() 
bgmchannel = pygame.mixer.Channel(0)
sfxchannel = pygame.mixer.Channel(1)
bgmchannel.set_volume(0.15)

def divide_string(s, max_length=500):
    return [s[i:i+max_length] for i in range(0, len(s), max_length)]

def download_first_audio(URL):
    URLS = [URL]
    # Options for yt-dlp
    ydl_opts = {
    'format': 'm4a/bestaudio/best',
    'outtmpl': 'asset/twitch/music',
    # ℹ️ See help(yt_dlp.postprocessor) for a list of available Postprocessors and their arguments
    'postprocessors': [{  # Extract audio using ffmpeg
        'key': 'FFmpegExtractAudio',
        'preferredcodec': 'mp3',
        
    }]
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        error_code = ydl.download(URLS)

def download_audio_from_query(query):
    # Perform a YouTube search
    videosSearch = VideosSearch(query, limit = 1)
    search_results = videosSearch.result()
    if len(search_results['result']) == 0:
        print("No videos found for the given query.")
        return "No results"
    video_url = search_results['result'][0]['link']
    download_first_audio(video_url)
    return search_results['result'][0]['title']

class Bot(commands.Bot):
    def __init__(self):
        super().__init__(token=token, prefix='!', initial_channels=[channelname])
        
    async def event_ready(self):
        # We are logged in and ready to chat and use commands...
        print(f'Logged in as | {self.nick}')
        print(f'User id is | {self.user_id}')

    async def event_message(self, message):
        if message.author:
            if message.content[0] != '!' and message.author.name != channelname:
                await self.send_websocket_message("newmessage")
        await self.handle_commands(message)
    
    async def event_usernotice_subscription(self, metadata):
        print(metadata)
        sendData = f"subscribed.{metadata.User.name}"
        await self.send_websocket_message(sendData)

    async def player_done(self):
        print('Finished playing')
    
    async def is_user_subscribed_for(self, user_id, user_name, minutes_required):
        # Check if admin
        if user_id == adminuserid:
            return True
            
        # Fetch user and their follow time
        user = self.create_user(adminuserid, channelname)
        followers = await user.fetch_channel_followers(token, user_id=user_id)

        # If user is not in the followers list
        if not followers:
            return False
            
        followtime = followers[0].followed_at
        current_time = datetime.utcnow().replace(tzinfo=timezone.utc)
        elapsed_time = current_time - followtime
        required_time = timedelta(minutes=minutes_required)  # Corrected this line
        # Check if elapsed time since following is greater than required time
        return elapsed_time >= required_time
    
    async def send_websocket_message(self, message):
        uri = "ws://localhost:8765"  # Modify if your server is on a different host.
        async with websockets.connect(uri) as websocket:
            await websocket.send(message)
            response = await websocket.recv()
            return response

    
    @commands.command()
    async def gamehelp(self, ctx: commands.Context):
        await ctx.send(f'!help, !stats, !attack, !heal, !res, !buy (item), !upgrade (stat), !dice (player) (amount), !accept, !reisler')
    @commands.command()
    async def help(self, ctx: commands.Context):
        await ctx.send(f'!gamehelp, !sa, !dc, !fw, !speak (mesaj), !speakeng (msg), !play (arama), !stop, !chatall, !chat, !vsgel')
    @commands.command()
    async def stats(self, ctx: commands.Context):
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def attack(self, ctx: commands.Context):
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def heal(self, ctx: commands.Context):
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def res(self, ctx: commands.Context):
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def reisler(self, ctx: commands.Context):
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def accept(self, ctx: commands.Context):
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def upgrade(self, ctx: commands.Context, *, message: str = "Default message"):
        sendData = f"{ctx.author.name}.{ctx.command.name}.{message}"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def dice(self, ctx: commands.Context, *, message: str = "Default message"):
        sendData = f"{ctx.author.name}.{ctx.command.name}.{message}"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)  
    @commands.command()
    async def buy(self, ctx: commands.Context, *, message: str = "Default message"):
        sendData = f"{ctx.author.name}.{ctx.command.name}.{message}"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
        
    @commands.command()
    async def sa(self, ctx: commands.Context, *, message: str = "Default message"):
        sendData = f"{ctx.author.name}.{ctx.command.name}.{message}"
        response = await self.send_websocket_message(sendData)
        await ctx.send(response)
    @commands.command()
    async def shake(self, ctx: commands.Context):
        MINUTES_REQUIRED = 10
        if not await self.is_user_subscribed_for(ctx.author.id, ctx.author.name, MINUTES_REQUIRED):
            await ctx.send(f"Sorry {ctx.author.name}, you need to be subscribed for at least {MINUTES_REQUIRED} minutes to use this command.")
            return
        sound = pygame.mixer.Sound("asset/sfx/shake.ogg")
        sfxchannel.play(sound)
        await ctx.send("anayn")
    @commands.command()
    async def chatall(self, ctx: commands.Context):
        user = self.create_user(self.user_id, self.nick)
        chatters = user.channel.chatters
        #print(chatters)
        messageText = ""
        chatterData = []
        # Fixed the loop to concatenate the message correctly
        for chatter in chatters:
            chatterData.append(chatter.name)
            messageText += chr(random.randint(0x1F600, 0x1F64F)) + "@" + chatter.name + chr(random.randint(0x1F600, 0x1F64F)) + chr(random.randint(0x1F600, 0x1F64F))
        sendData = f"chatterData.{chatterData}"
        try:
            await self.send_websocket_message(sendData)
        except:
            pass
        for mes in divide_string(messageText):
            await ctx.send(mes)
    @commands.command()
    async def speak(self, ctx: commands.Context, *, search: str = "asd") -> None:
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        if response != "ok":
            await ctx.send(response)
            return
        speech = gTTS(text=search, lang='tr', slow=False)
        speech.save("asset/twitch/play.mp3")
        sound = pygame.mixer.Sound("asset/twitch/play.mp3")
        sfxchannel.play(sound)
        await ctx.send(f'Now playing: {search}')
    @commands.command()
    async def speakeng(self, ctx: commands.Context, *, search: str = "asd") -> None:
        sendData = f"{ctx.author.name}.{ctx.command.name}.null"
        response = await self.send_websocket_message(sendData)
        if response != "ok":
            await ctx.send(response)
            return
        speech = gTTS(text=search, lang='en', slow=False)
        speech.save("asset/twitch/play.mp3")
        sound = pygame.mixer.Sound("asset/twitch/play.mp3")
        sfxchannel.play(sound)
        await ctx.send(f'Now playing: {search}')
    @commands.command()
    async def vsgel(self, ctx: commands.Context):
        await ctx.send(f'{ctx.author.name}, nick DRİFT KİNq, ekle aslanım')
    @commands.command()
    async def dc(self, ctx: commands.Context):
        await ctx.send(f'{ctx.author.name} buyur reis: ' + discordlink)
    @commands.command()
    async def fw(self, ctx: commands.Context):
        user = self.create_user(self.user_id, self.nick)
        followers = await user.fetch_channel_followers(token)
        #print(followers)
        random_follower = random.choice(followers)
        await ctx.send(f"respect @{random_follower.user.name}")
    @commands.command()
    async def chat(self, ctx: commands.Context):
        user = self.create_user(self.user_id, self.nick)
        chatters = user.channel.chatters
        #print(chatters)
        randomChatter = random.choice(list(chatters))
        await ctx.send(f"Welcome @{randomChatter.name} 😍🥰")
    @commands.command()
    async def play(self, ctx: commands.Context, *, search: str = "iyi ki doğdun alp") -> None:
        MINUTES_REQUIRED = 31
        if not await self.is_user_subscribed_for(ctx.author.id, ctx.author.name, MINUTES_REQUIRED):
            await ctx.send(f"Sorry {ctx.author.name}, you need to be subscribed for at least {MINUTES_REQUIRED} minutes to use this command.")
            return
        if bgmchannel.get_busy() == False:
            queryresult = download_audio_from_query(search)
            sound = pygame.mixer.Sound("asset/twitch/music.mp3")
            bgmchannel.play(sound)
            
            try:
                sendData = f"{ctx.author.name}.{ctx.command.name}.{queryresult}"
                await self.send_websocket_message(sendData)
            except:
                pass
            
            await ctx.send(f'Now playing: {queryresult}')
        else:
            await ctx.send(f'{ctx.author.name}, sabret yeğen...')
    @commands.command()
    async def stop(self, ctx: commands.Context):
        if bgmchannel.get_busy() == True:
            bgmchannel.stop()
            await ctx.send(f'Stopped music.')


def run_bot():
    bot_instance = Bot()
    bot_instance.run()
    
run_bot()