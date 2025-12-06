#ifndef NETWORK_UTILS_H
#define NETWORK_UTILS_H

#include <netinet/in.h>

// Existing function declarations
int connect_to_server(const char *hostname, int port);
int send_data(int sockfd, const void *buf, size_t len);
int receive_data(int sockfd, void *buf, size_t len);

// Add DNS address retrieval function prototype if not defined
#ifndef GET_DNS_ADDR_DECLARED
#define GET_DNS_ADDR_DECLARED
int get_dns_addr(struct in_addr *pdns_addr);
#endif

#endif // NETWORK_UTILS_H

