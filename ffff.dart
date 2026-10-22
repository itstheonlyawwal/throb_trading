if (response.statusCode == 200) {
final data = jsonDecode(response.body);
UserSession.instance.username = data['username'];
UserSession.instance.token = data['token'];


if (!mounted) return;
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => MainShell()),
);
} else {
final data = jsonDecode(response.body);
setState(() => _error = data['detail'] ?? 'Something went wrong. Please try again.');
}
}catch (e) {
if (!mounted) return;
setState(() => _error = 'DEBUG ERROR: $e');                                              //Something went wrong. Please try again.
} finally {
if (mounted) setState(() => _isLoading = false);
}
}








if (response.statusCode == 200) {
final data = jsonDecode(response.body);
UserSession.instance.username = data['username'];
UserSession.instance.token =
data['token']; // add this field to UserSession

if (!mounted) return;
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => MainShell()),
);
} else {
final data = jsonDecode(response.body);
setState(() => _error = data['detail'] ?? 'Invalid email or password.');
}
} catch (e) {
if (!mounted) return;
setState(() => _error = 'DEBUG ERROR: $e');                                                     //Something went wrong. Please try again.
} finally {
if (mounted) setState(() => _isLoading = false);
}}