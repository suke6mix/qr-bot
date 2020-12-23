class LinebotController < ApplicationController
    # gem 'line-bot-api'
    require 'line/bot'
    require 'rqrcode'

    # If you using rails 6 and use ngrok in development
    # you must edit the development.rb file in 
    # config/environments for add config.hosts << "a0000000.ngrok.io" 
    # where a0000000.ngrok.io is the url supplied by ngrok without https:// , 
    # if this no work so you must add skip_before_action :verify_authenticity_token in you controller.
    # skip_before_action :verify_authenticity_token

    # callbackアクションの
    # CSRF（クロスサイトリクエストフォージェリ）トークン認証を無効
    protect_from_forgery :except => [:callback]

    def client
        @client ||= Line::Bot::Client.new { |config|
            config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
            config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
        }
    end

    def callback
        body = request.body.read

        # X-Line-Signatureリクエストヘッダーに含まれる署名を検証して、
        # リクエストがLINEプラットフォームから送信されたことを確認する。
        signature = request.env['HTTP_X_LINE_SIGNATURE']
        unless client.validate_signature(body, signature)
            head :bad_request
        end

        events = client.parse_events_from(body)

        events.each { |event|
            case event
            when Line::Bot::Event::Message
                # 入力値をevent.typeで受け取る
                case event.type
                # 入力値がテキストタイプの時に反応する
                when Line::Bot::Event::MessageType::Text
                    # どのような返信にするか指定する
                    message = {
                        # タイプをテキストにする
                        type: 'text',
                        # テキストの内容
                        text: event.message['text']
                    }
                    # reply時にコード実行
                    client.reply_message(event['replyToken'], message)
                end
            end
        }
        head :ok
    end
end
