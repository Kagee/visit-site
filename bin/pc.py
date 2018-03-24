import pychrome
import sys

# create a browser instance
browser = pychrome.Browser(url="http://127.0.0.1:9222")
# https://chromedevtools.github.io/devtools-protocol/tot/Network/#event-requestWillBeSent
# create a tab
tab = browser.new_tab()

requests = {}

# register callback if you want
def request_will_be_sent(**kwargs):
    requestId = kwargs.get('requestId')
    URL = kwargs.get('request').get('url')
    isDataURL = URL.startswith("data:")
    requests[requestId] = {
            "URL" : URL,
            "isDataURL": isDataURL
    }
    if isDataURL:
        return 
    rr = kwargs.get('redirectResponse')
    if rr:
        print("[LOADSTART,REDIRECT];%s;%s;%s;" %(requestId,kwargs.get('redirectResponse').get('url'), URL))
    else:
        print("[LOADSTART];%s;%s;" % (requestId, URL))

def loading_finished(**kwargs):
    requestId = kwargs.get('requestId')
    URL = requests[kwargs.get('requestId')]["URL"]
    if not requests[kwargs.get('requestId')]["isDataURL"]:
        print("[LOADEND];%s;%s" % (requestId, URL))

def frame_navigated(**kwargs):
    URL = kwargs.get('url')
    loaderId = kwargs.get('frameId')
    print("[NAVIGATED];%s;%s" % (loaderId, URL))
    print(kwargs)
    # this is hella uglyi
    if primaryFrameId == loaderId:
        print("REACHED NAVIGATED, semi-stopping event handling")
        # https://docs.python.org/3/library/threading.html
        tab._stopped.set()

tab.Network.requestWillBeSent = request_will_be_sent
tab.Network.loadingFinished = loading_finished
tab.Page.frameStoppedLoading = frame_navigated


# start the tab 
tab.start()

# Enable notifications by calling methods
tab.Network.enable()
tab.Page.enable()

# https://chromedevtools.github.io/devtools-protocol/tot/Security#method-setIgnoreCertificateErrors

# call method with timeout 
# https://chromedevtools.github.io/devtools-protocol/tot/Page#method-navigate
primaryFrameId = tab.Page.navigate(url="http://" + sys.argv[1], _timeout=30)["frameId"]
#primaryFrameId = res["frameId"]
# Should take a time here and calculate ms for load
print("[NAVIGATING] %s" % (primaryFrameId,))

# Page.handleJavaScriptDialog


# wait for loading
# This waits and handles events as it is waiting,
# until timeout or tab.stop()
tab.wait(60)
# More hella ugly
print("navigated-load or 60s load complete, sleeping 10s before xsccreenshot")
tab._stopped.clear()
tab.wait(10)
print("done waitin, taking screenshot")
# Tab must be active for screenshot to be taken
import base64
data = tab.Page.captureScreenshot(format="png", 
        clip={"x":0, "y":0,"width":1920, "height":900,"scale":1},
        fromSurface=True)
f = open('./image.png', 'wb')
f.write(base64.b64decode(data["data"]))
f.close()

# stop the tab (stop handle events and stop recv message from chrome)
tab.stop()

# close tab
browser.close_tab(tab)
