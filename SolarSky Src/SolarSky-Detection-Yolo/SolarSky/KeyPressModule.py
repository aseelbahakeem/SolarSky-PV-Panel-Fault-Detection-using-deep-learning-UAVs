
import pygame

def init():
    pygame.init()
    win = pygame.display.set_mode((400, 400))

def getKey(KeyName):
    ans = False
    for eve in pygame.event.get(): pass
    KeyInput = pygame.key.get_pressed()
    myKey = getattr(pygame, 'K_{}'.format(KeyName))
    if KeyInput[myKey]:
        ans = True
    pygame.display.update()
    return ans
def main():
    if getKey("LEFT"):
        print("left Key Pressed")
    if getKey("RIGHT"):
        print("right Key Pressed")

if __name__ == '__main__':
    init()
    while True:
        main()