# coding: utf-8

class BigDeployButton
  require 'pi_piper'

  include PiPiper

  DEPLOY_COMMAND = '`cat deploy_command`'

  def initialize
    p "Initializing..."

    @button = Pin.new(pin: 24, direction: :in, trigger: :rising)
    @white_led = Pin.new(pin: 22, direction: :out)
    @blue_led = Pin.new(pin: 21, direction: :out)

    @blink_threads = {}
    @deploy_in_progress = false
    
    @blue_led.on

    listen_to_button
  end

  def listen_to_button
    Thread.new do
      loop do
        @button.wait_for_change 
        deploy if @button.on? 
      end 
    end.abort_on_exception = true  
    
    p "Waiting..."
    PiPiper.wait
    p "Finished waiting"
  end

  def deploy
    return if @deploy_in_progress # Prevent multiple deploy requests

    @deploy_in_progress = true
    notify_deploy_in_progress

    system(DEPLOY_COMMAND)
    successful_deploy = $?.success?
    successful_deploy ? notify_deploy_finished_ok : notify_deploy_finished_with_errors

    @deploy_in_progress = false
  end

  def notify_deploy_in_progress
    p "Deploying..."
    @white_led_blink.exit if @white_led_blink
    blink_white_led(on_time: 1, off_time: 0.7)
  end
 
  def notify_deploy_finished_ok
    p "Deploy finished OK"
    @white_led_blink.exit
    @white_led.off
  end

  def notify_deploy_finished_with_errors
    p "Deploy finished with errors!"
    blink_white_led
    p "Blinking white led"
  end

  def blink_white_led(options = { on_time: 0.2, off_time: 0.2 })
    @white_led_blink = blink_led(@white_led, options)
  end

  def blink_led(led, options = { on_time: 0.2, off_time: 0.2 })
    @blink_threads[led.pin] = Thread.new do
      loop do
        led.off
        sleep options[:off_time]
        led.on
        sleep options[:on_time]
      end.abort_on_exception = true
    end
  end
end

