package main

// Create a go application to build using kaniko
//         - Write a go server that listens for connection on given port
//         - Expose kill and hello RESTful endpoints using gin-gonic
// Write a sample build file for the Go application
//         - Multi state build
// Build application using kaniko
//         - Run kaniko as a docker container
//         - Pull code from GitHub and build with :github tag to image
//         - Take gzip file as source and build with tag :gzip
//         - Push image to hub.docker.com

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// Prepare yourself, for we shall unleash the power of Gin!
	router := gin.Default()

	// Ah, the /hello endpoint, where the world shall be greeted with unparalleled joy!
	router.GET("/hello", func(c *gin.Context) {
		c.String(http.StatusOK, "Hello, world!")
	})

	// But wait, there's more! The /kill endpoint, harbinger of server destruction!
	router.GET("/kill", func(c *gin.Context) {
		// Aha! Witness the server's demise, as it gracefully bows out of existence!
		// May its memory forever dwell in the depths of digital oblivion!
		os.Exit(0)
	})

	// And now, let the server be born, ready to serve the masses!
	server := &http.Server{
		Addr:    ":10000",
		Handler: router,
	}

	// The server awakens, commencing its eternal duty to respond to the beck and call of the world!
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Println("Server error:", err)
		}
	}()

	// But lo! The server shall not reign forever. It must heed the signal of termination, to gracefully step aside.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	// And so, with a heavy heart, the server shall enter the realm of darkness, bowing down before the unstoppable force of time.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// But fear not, for even in its final moments, the server shall shutdown gracefully, leaving behind a legacy of service.
	if err := server.Shutdown(ctx); err != nil {
		fmt.Println("Server shutdown error:", err)
	}
}
