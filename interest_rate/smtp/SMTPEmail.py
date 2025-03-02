import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from config.config import SMTP_SERVER, SMTP_PORT, EMAIL_SENDER, EMAIL_PASSWORD, EMAIL_RECEIVER

class SMTPEmail:
    @staticmethod
    def send_email(subject, body):
        try:
            msg = MIMEMultipart()
            msg["From"] = EMAIL_SENDER
            msg["To"] = EMAIL_RECEIVER
            msg["Subject"] = subject
            msg.attach(MIMEText(body, "plain"))

            server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)

            server.starttls()
            server.login(EMAIL_SENDER, EMAIL_PASSWORD)
            server.sendmail(EMAIL_SENDER, EMAIL_RECEIVER, msg.as_string())
            server.quit()
            
            print("Email sent successfully!")
        except Exception as e:
            print(f"Error: {e}")

    @staticmethod
    def send_warning(tickers: list):
        if len(tickers) > 0:
            subject = "Warning! Higher probability!"
            body = "Probability has increased for companies: "

            for i, t in enumerate(tickers):
                if i != 0:
                    body += ", "
            
                body += t

            body += "."

            __class__.send_email(subject, body)