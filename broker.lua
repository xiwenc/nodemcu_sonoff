local dispatcher = {}
local TOPIC = "/" .. MQTT_MAINTOPIC .. "/" .. MQTT_CLIENTID

-- client activation
m = mqtt.Client(MQTT_CLIENTID, 180, MQTT_USER, MQTT_PASSWORD)

-- actions
local function switch_power(m, pl)
    if pl == "on" or pl == "ON" then
        gpio.write(GPIO_SWITCH, gpio.HIGH)
        print("MQTT : plug ON for ", MQTT_CLIENTID)
    else
        gpio.write(GPIO_SWITCH, gpio.LOW)
        print("MQTT : plug OFF for ", MQTT_CLIENTID)
    end
    mqtt_update()
end

-- Update status to MQTT
function mqtt_update()
    mqtt_activity()
    if gpio.read(GPIO_SWITCH) == 1 then
        m:publish(TOPIC .. "/state", "ON", 0, 0)
    else
        m:publish(TOPIC .. "/state", "OFF", 0, 0)
    end
end

function mqtt_activity()
    if LED ~= "mqtt" then
        return
    end
    if gpio.read(GPIO_LED) == 1 then
        gpio.write(GPIO_LED, gpio.HIGH)
    end
    gpio.write(GPIO_LED, gpio.LOW)
    tmr.alarm(5, 50, 0, function() gpio.write(GPIO_LED, gpio.HIGH) end)
end

-- Pin to toggle the status
buttondebounced = 0
buttonPin = 3
buttonDebounce = 250
gpio.trig(buttonPin, "down",function (level)
    if buttondebounced == 0 then
        buttondebounced = 1
        tmr.alarm(6, buttonDebounce, 0, function() buttondebounced = 0; end)

        --Change the state
        if gpio.read(GPIO_SWITCH) == 1 then
            gpio.write(GPIO_SWITCH, gpio.LOW)
            print("Was on, turning off")
        else
            gpio.write(GPIO_SWITCH, gpio.HIGH)
            print("Was off, turning on")
        end

        mqtt_update()
    end
end)


-- events
m:lwt('/lwt', MQTT_CLIENTID .. " died !", 0, 0)

m:on('connect', function(m)
    print('MQTT : ' .. MQTT_CLIENTID .. " connected to : " .. MQTT_HOST .. " on port : " .. MQTT_PORT)
    m:subscribe(TOPIC, 0, function (m)
        print('MQTT : subscribed to ',  TOPIC)
    end)
end)

m:on('offline', function(m)
    print('MQTT : disconnected from ', MQTT_HOST)
    tmr.alarm(1, 10000, 0, function()
        node.restart();
    end)
end)

m:on('message', function(m, topic, pl)
    mqtt_activity()
    print('MQTT : Topic ', topic, ' with payload ', pl)
    if pl~=nil and dispatcher[topic] then
        dispatcher[topic](m, pl)
    end
end)


-- Start
gpio.mode(GPIO_SWITCH, gpio.OUTPUT)
dispatcher[TOPIC] = switch_power
m:connect(MQTT_HOST, MQTT_PORT, 0, 1)
