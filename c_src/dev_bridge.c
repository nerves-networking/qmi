// SPDX-FileCopyrightText: 2020 Frank Hunleth
// SPDX-FileCopyrightText: 2023 Jon Carstens
//
// SPDX-License-Identifier: Apache-2.0
//
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include "eframer.h"

enum commands {
    CMD_WRITE = 1,
    CMD_IOCTL,
    CMD_POSITION
};

enum notifications {
    NOTIF_RESPONSE = 0,
    NOTIF_DATA = 1,
    NOTIF_ERROR = 2
};

// This is the extra space to allocate on receive and transmit
// buffers to accommodate metadata
#define MESSAGE_OVERHEAD 256

static struct eframer framer;
static int dev_fd;
static size_t max_rx_message;
static size_t max_tx_message;

static const char *errnum_to_posix(int errnum)
{
    switch (errnum) {
    case EPERM: return "eperm";
    case ENOENT: return "enoent";
    case ESRCH: return "esrch";
    case EINTR: return "eintr";
    case EIO: return "eio";
    case ENXIO: return "enxio";
    case E2BIG: return "e2big";
    case ENOEXEC: return "enoexec";
    case EBADF: return "ebadf";
    case ECHILD: return "echild";
    case EAGAIN: return "eagain";
    case ENOMEM: return "enomem";
    case EACCES: return "eacces";
    case EFAULT: return "efault";
    case ENOTBLK: return "enotblk";
    case EBUSY: return "ebusy";
    case EEXIST: return "eexist";
    case EXDEV: return "exdev";
    case ENODEV: return "enodev";
    case ENOTDIR: return "enotdir";
    case EISDIR: return "eisdir";
    case EINVAL: return "einval";
    case ENFILE: return "enfile";
    case EMFILE: return "emfile";
    case ENOTTY: return "enotty";
    case ETXTBSY: return "etxtbsy";
    case EFBIG: return "efbig";
    case ENOSPC: return "enospc";
    case ESPIPE: return "espipe";
    case EROFS: return "erofs";
    case EMLINK: return "emlink";
    case EPIPE: return "epipe";
    case EDOM: return "edom";
    case ERANGE: return "erange";
    default: return "ebadmsg";
    }
}

static void report_failure(int errnum)
{
    uint8_t *buffer = eframer_tx_buffer(&framer);
    const char *reason = errnum_to_posix(errnum);
    size_t len = strlen(reason);
    buffer[0] = NOTIF_ERROR;
    memcpy(buffer + 1, reason, len);
    eframer_send(&framer, len + 1);
    exit(EXIT_FAILURE);
}

static void handle_device_ready(void)
{
    uint8_t *buffer = eframer_tx_buffer(&framer);

    buffer[0] = NOTIF_DATA;
    ssize_t amt = read(dev_fd, buffer + 1, max_rx_message);
    if (amt < 0 && errno != EINTR)
        report_failure(errno);

    eframer_send(&framer, amt + 1);
}

static void request_handler(const uint8_t *request, size_t len, void *cookie)
{
    (void) cookie;

    uint8_t cmd = request[0];
    uint8_t from_len = request[1];
    const uint8_t *payload = &request[2 + from_len];
    size_t payload_len = len - from_len - 2;

    uint8_t *response = eframer_tx_buffer(&framer);
    response[0] = NOTIF_RESPONSE;
    memcpy(response + 1, request + 1, from_len + 1);
    size_t response_len = from_len + 2;

    switch (cmd) {
    case CMD_WRITE:
    {
        ssize_t rc;

        if (payload_len <= max_tx_message) {
            rc = write(dev_fd, payload, payload_len);
        } else {
            rc = -1;
            errno = E2BIG;
        }
        if (rc < 0) {
            response[response_len] = 0xff;
            response[response_len + 1] = 0xff;
            const char *reason = errnum_to_posix(errno);
            size_t errno_len = strlen(reason);
            memcpy(&response[response_len + 2], reason, errno_len);
            eframer_send(&framer, response_len + 2 + errno_len);
        } else {
            response[response_len] = (rc >> 8) & 0xff;
            response[response_len + 1] = rc & 0xff;
            eframer_send(&framer, response_len + 2);
        }
        break;
    }
    default:
        break;
    }
}

int main(int argc, char *argv[])
{
    if (argc != 4)
        exit(EXIT_FAILURE);

    max_rx_message = strtoul(argv[2], NULL, 0);
    max_tx_message = strtoul(argv[3], NULL, 0);

    // For the framer, the max message size to receive from Erlang is the max size that we'd need to send to the device.
    // Same thing for the receive size.
    struct eframer_config config = {
        .max_rx_message_size = max_tx_message + MESSAGE_OVERHEAD,
        .max_tx_message_size = max_rx_message + MESSAGE_OVERHEAD,
        .rx_handler = request_handler,
        .cookie = 0
    };

    eframer_init(&framer, &config);

    int oflag = 0; //O_CLOEXEC;
    if (max_tx_message > 0 && max_rx_message > 0)
        oflag |= O_RDWR;
    else if (max_rx_message > 0)
        oflag |= O_RDONLY;
    else if (max_tx_message > 0)
        oflag |= O_WRONLY;
    else
        report_failure(EINVAL);

    dev_fd = open(argv[1], oflag);
    if (dev_fd < 0)
        report_failure(errno);

    for (;;) {
        struct pollfd fdset[2];
        int numfds = 1;

        fdset[0].fd = STDIN_FILENO;
        fdset[0].events = POLLIN;
        fdset[0].revents = 0;

        if (max_rx_message > 0) {
            fdset[1].fd = dev_fd;
            fdset[1].events = POLLIN;
            numfds = 2;
        }
        fdset[1].revents = 0;

        int rc = poll(fdset, numfds, -1);
        if (rc < 0) {
            // Retry if EINTR
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "poll");
        }

        if (fdset[1].revents & (POLLIN | POLLHUP))
            handle_device_ready();

        // Any notification from Erlang is to exit
        if (fdset[0].revents & (POLLIN | POLLHUP))
            eframer_process(&framer);
    }

    return 0;
}
