#include <security/pam_appl.h>
#include <iostream>
#include <string>
#include <cstring>

static std::string password;

int conv_func(int num_msg, const struct pam_message** msg,
              struct pam_response** resp, void*) {
    if (num_msg != 1) return PAM_CONV_ERR;
    *resp = (struct pam_response*)calloc(num_msg, sizeof(struct pam_response));
    (*resp)[0].resp = strdup(password.c_str());
    return PAM_SUCCESS;
              }

              int main() {
                  std::string username;
                  std::cout << "Username: ";
                  std::cin >> username;
                  std::cout << "Password: ";
                  std::cin >> password;

                  pam_handle_t* pamh = nullptr;
                  struct pam_conv conv = { conv_func, nullptr };

                  int ret = pam_start("system-auth", username.c_str(), &conv, &pamh);
                  if (ret != PAM_SUCCESS) {
                      std::cerr << "pam_start failed: " << pam_strerror(pamh, ret) << "\n";
                      return 1;
                  }

                  ret = pam_authenticate(pamh, 0);
                  if (ret == PAM_SUCCESS) {
                      std::cout << "Authentication success!\n";
                  } else {
                      std::cerr << "Authentication failed: " << pam_strerror(pamh, ret) << "\n";
                  }

                  pam_end(pamh, ret);
                  return 0;
              }
