import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class GetServerToken {
  Future<String> getAccessToken() async {
    final servicesAccountJson = {
      "type": "service_account",
      "project_id": "grubb-ba0e4",
      "private_key_id": "4de94a9defda891bf58132972534f8643b6f2c56",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDEJZ96L/hXRl6d\nP7j+A+X0xtQ3B4q/goR4SVl0+gAhMB12Df0CaxNAiGOUJFW2JkpId7E8WqZxrKHE\n3bhyTpoZK2MuuL0qTKckXbf5sVq9ju6KXPpqr5ZRxkyF+YgsbGyQ0OqmRqpaa2xS\n05Zz+8PTOU1k5d4qoN33LjGvMHGgDcz1tVfdZzz5IHO6JEy1dALbtvjODttE3019\nm5gtNnE6HgOT247wWXLoEmdVkEkm5tAHSi87srcaCKniB04P76ytrfEU5wbInstN\nC099oQJaqsfijDsXg3kNfEhB7OXrLZYZOgy9DJXNPFfiFF6m4Ac2pOWNlrjKr/31\nV5fv+btdAgMBAAECggEAF9Xql1KU/yYSAVHpDRU0MJao2zcTaUpXBrcDI+/tbBsI\nuXvhrxWL9V+dmjcAI25rwHqrEwaBC3dLAT1gWKOsnjpjhx3z/tvpw8WPwcwHltlz\nq2S5GZXU0oMicXVtUtiqKL76hNI5iVtcgoQr2FRT66se+I/me4+o6Yy3hO6CIEzW\ni5F4I+6ALKJleRXgfOOgHyUitjtA/0GiVu2ywDcXH4h5z+pkEmPmXqreFD1bUV5e\nqXUR7mVG3+hd7jSpM7jT9e9cZnnzK/t5Co8g6I/JkP+qbHAk22ie9137OqCYsIav\nFUFfQp+9/OWUz4SQ+X5FA8a3r/bTC3zoZ2lz22m9EQKBgQDmfbuZ3j4HyNrfaZPw\nYfgBBc8k1dYNLd6rHzFejVkfnby6AKfpGSWifnQCvgDD9hdHPeQ1JK7/W5vO61hD\nzh+QF8W4v9ZxR6vDsOxnLNDYGQML8lBy5arfThD2tGouXy1wRe/4cjIfh61r1POm\nf+He9guUc8FgOwuKNgK/I05SqwKBgQDZ2tofB04bPlUyvX2qiqQXWQPtUegVHPYK\nHRiGETYwGJmPxC8E9rR/Mmsx1QoR5Ym3FKAdNYNbACc8NwSxRLR6OwYaklI8FFgP\nQl4Og3NkOFuiWRI1oSXMyzfNvXnd9K8G9+ttyIG5HK8j8piq168hHWCAlrsl06l4\nXa47hSDqFwKBgE6nQUl0iX5mkCoFATLae6L9tH5BalX8/Ssv7czyNyOO1EQ0zRfC\nORGGTVhSNjio1bC98g4ggocpX7XwoaIhyKuHMTWmYSsu5fJVgZaDuJDFmECPY9yR\newnQvgEx97nzSLIza3xAm9IenpNZi/uZUB6hn7n89lQ8UefMHovTJHsZAoGACeVg\nHSK20JP/SMPEzpdnpsvbWs9qrHLZVlJGB+kGPh8P8rDlteMDBfgjWGsl/vQfUlq0\nfz8sDVkvbxPMucS2Mgs2VsSoyaPe8CqCnUQpXLcWqoRDSH5eejQM/+KIg6WWwclH\nP4BpLCB6cDaX6sLLaMSt2ol+TNSVkSsoO/nrKdcCgYEAw1HCJV+ELqdwg6Qr4MRV\nFpfMQ/P8E2DCnlma5+RmyeNWtesnmtHJ0yiYpBiVyh1I/hoAwMCAAdlAslUPhRER\nBNDRZli77j4XDWhqfF52gysO0YQkSZiCVXTcNvV6HYSQcm3CMB3Exq911C9IlYkr\nsykcelt2SxSii04bgoSCisA=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "notifications-latest-upload@grubb-ba0e4.iam.gserviceaccount.com",
      "client_id": "112319154723902474293",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/notifications-latest-upload%40grubb-ba0e4.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(servicesAccountJson),
      scopes,
    );

    /// Get Access Token
    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(servicesAccountJson),
          scopes,
          client,
        );

    client.close();

    return credentials.accessToken.data;
  }
}
